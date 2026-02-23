import SwiftUI

struct YanHakAnaliziView: View {
    @EnvironmentObject var appTheme: AppTheme
    @EnvironmentObject var yanHakKayitStore: YanHakKayitStore
    var duzenlenenKayit: YanHakKayit? = nil
    
    @StateObject private var mevcutIs = YanHakVerisi()
    @StateObject private var teklif = YanHakVerisi()
    @State private var currentStep = 0
    
    @State private var mevcutUcretText = ""
    @State private var teklifUcretText = ""
    @State private var mevcutPrimText = ""
    @State private var teklifPrimText = ""
    @State private var mevcutYemekKartiText = ""
    @State private var teklifYemekKartiText = ""
    @State private var mevcutYolUcretiText = ""
    @State private var teklifYolUcretiText = ""
    @State private var mevcutYakitText = ""
    @State private var teklifYakitText = ""
    @State private var mevcutInternetText = ""
    @State private var teklifInternetText = ""
    @State private var mevcutGozDisTutarText = ""
    @State private var teklifGozDisTutarText = ""
    
    @State private var akisTamamlandi = false
    
    /// Groq API anahtarı (console.groq.com). Git push öncesi koddan kaldırın.
    @AppStorage("groq_api_key") private var groqAPIKey = ""
    @State private var groqAPIKeyGecici = ""
    @State private var aiYorumLoading = false
    @State private var aiYorumText: String? = nil
    @State private var aiYorumHata: String? = nil
    @State private var raporGosteriliyor = false
    @State private var kaydetBasarili = false
    @State private var detayAccordionAcik = false
    @State private var showHolidaysSheet = false
    
    private let temaRengi = Color(hex: "F59E0B")
    private let toplamAdim = 12
    
    var body: some View {
        ZStack {
            appTheme.background.ignoresSafeArea()
            
            if akisTamamlandi {
                karşılaştırmaFormu
            } else {
            VStack(spacing: 0) {
                // Adım göstergesi
                stepIndicator
                
                ScrollView {
                    VStack(spacing: 24) {
                        switch currentStep {
                        case 0: soru1Ucret
                        case 1: soru2Kidem
                        case 2: soru3Terfi
                        case 3: soru4MaasPeriyodu
                        case 4: soru5CalismaModeli
                        case 5: soru6YillikIzin
                        case 6: soru7Telefon
                        case 7: soru8PrimBonus
                        case 8: soru9Sigorta
                        case 9: soru10Yemek
                        case 10: soru11Ulasim
                        case 11: soru12InternetElektrik
                        default: soru1Ucret
                        }
                    }
                    .padding(20)
                }
                .scrollDismissesKeyboard(.interactively)
                
                // İleri / Geri
                HStack(spacing: 16) {
                    if currentStep > 0 {
                        Button {
                            withAnimation { currentStep -= 1 }
                        } label: {
                            Label("Geri", systemImage: "chevron.left")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(appTheme.listRowBackground)
                                .foregroundColor(appTheme.textPrimary)
                                .cornerRadius(14)
                        }
                    }
                    Button {
                        if currentStep < toplamAdim - 1 {
                            withAnimation { currentStep += 1 }
                        } else {
                            withAnimation { akisTamamlandi = true }
                        }
                    } label: {
                        Label(currentStep < toplamAdim - 1 ? "Devam" : "Tamam", systemImage: "chevron.right")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(temaRengi)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }
                }
                .padding(16)
            }
            }
        }
        .navigationTitle("Yan Hak Analizi")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(appTheme.isLight ? .light : .dark, for: .navigationBar)
        .toolbarBackground(appTheme.background, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !akisTamamlandi {
                    Button("Örnek Doldur") {
                        ornekDoldur()
                        akisTamamlandi = true
                    }
                    .foregroundColor(temaRengi)
                }
            }
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .onAppear {
            if let kayit = duzenlenenKayit {
                loadKayit(kayit)
            }
            if mevcutIs.brutMaas > 0 { mevcutUcretText = formatNumberGoster(mevcutIs.brutMaas) }
            if teklif.brutMaas > 0 { teklifUcretText = formatNumberGoster(teklif.brutMaas) }
        }
    }
    
    private func formatNumberGoster(_ d: Double) -> String {
        guard d > 0 else { return "" }
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.maximumFractionDigits = 0
        fmt.decimalSeparator = ","
        fmt.groupingSeparator = "."
        return fmt.string(from: NSNumber(value: d)) ?? ""
    }
    
    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<toplamAdim, id: \.self) { i in
                Circle()
                    .fill(i <= currentStep ? temaRengi : appTheme.textSecondary.opacity(0.4))
                    .frame(width: 8, height: 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
    
    // Soru 1: Ücret — Mevcut iş + Teklif, her biri için brüt/net seçimi
    private var soru1Ucret: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Ücret ne kadar?")
                .font(.title2.weight(.bold))
                .foregroundColor(appTheme.textPrimary)
            
            // Mevcut İş Yeri
            VStack(alignment: .leading, spacing: 12) {
                Text("Mevcut İş Yeri")
                    .font(.headline)
                    .foregroundColor(appTheme.textPrimary)
                KrediTextField(title: "Ücret (₺/ay)", text: $mevcutUcretText, placeholder: "50.000", keyboardType: .decimalPad, formatThousands: true)
                    .onChange(of: mevcutUcretText) { _, v in mevcutIs.brutMaas = parseFormattedNumber(v) ?? 0 }
                
                Text("Ücret brüt mü net mi?")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(appTheme.textSecondary)
                HStack(spacing: 12) {
                    Button {
                        mevcutIs.ucretBrutMu = true
                    } label: {
                        Text("Brüt")
                            .font(.subheadline)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(mevcutIs.ucretBrutMu ? temaRengi : appTheme.cardBackgroundSecondary)
                            .foregroundColor(mevcutIs.ucretBrutMu ? .white : appTheme.textPrimary)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    Button {
                        mevcutIs.ucretBrutMu = false
                    } label: {
                        Text("Net")
                            .font(.subheadline)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(!mevcutIs.ucretBrutMu ? temaRengi : appTheme.cardBackgroundSecondary)
                            .foregroundColor(!mevcutIs.ucretBrutMu ? .white : appTheme.textPrimary)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(appTheme.listRowBackground)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(temaRengi.opacity(0.3), lineWidth: 1))
            )
            
            // Teklifte Bulunan İş Yeri
            VStack(alignment: .leading, spacing: 12) {
                Text("Teklifte Bulunan İş Yeri")
                    .font(.headline)
                    .foregroundColor(appTheme.textPrimary)
                KrediTextField(title: "Ücret (₺/ay)", text: $teklifUcretText, placeholder: "55.000", keyboardType: .decimalPad, formatThousands: true)
                    .onChange(of: teklifUcretText) { _, v in teklif.brutMaas = parseFormattedNumber(v) ?? 0 }
                
                Text("Ücret brüt mü net mi?")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(appTheme.textSecondary)
                HStack(spacing: 12) {
                    Button {
                        teklif.ucretBrutMu = true
                    } label: {
                        Text("Brüt")
                            .font(.subheadline)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(teklif.ucretBrutMu ? temaRengi : appTheme.cardBackgroundSecondary)
                            .foregroundColor(teklif.ucretBrutMu ? .white : appTheme.textPrimary)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    Button {
                        teklif.ucretBrutMu = false
                    } label: {
                        Text("Net")
                            .font(.subheadline)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(!teklif.ucretBrutMu ? temaRengi : appTheme.cardBackgroundSecondary)
                            .foregroundColor(!teklif.ucretBrutMu ? .white : appTheme.textPrimary)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(appTheme.listRowBackground)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(temaRengi.opacity(0.3), lineWidth: 1))
            )
        }
    }
    
    // Soru 2: Mevcut işte kaç yıl (kıdem tazminatı için)
    private var soru2Kidem: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Mevcut iş yerinde kaç yıldır çalışıyorsunuz?")
                .font(.title2.weight(.bold))
                .foregroundColor(appTheme.textPrimary)
            Text("Kıdem tazminatı hesaplamasında kullanılacak.")
                .font(.subheadline)
                .foregroundColor(appTheme.textSecondary)
            
            kartIcerik {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Mevcut İş Yeri")
                        .font(.headline)
                        .foregroundColor(appTheme.textPrimary)
                    HStack(spacing: 16) {
                        Text("Yıl")
                            .foregroundColor(appTheme.textSecondary)
                        Picker("", selection: Binding(
                            get: { mevcutIs.mevcutIsYil ?? 1 },
                            set: { mevcutIs.mevcutIsYil = $0 }
                        )) {
                            ForEach(1...50, id: \.self) { y in
                                Text("\(y)").tag(y)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
            }
        }
    }
    
    // Soru 3: Terfi / Aynı ünvan
    private var soru3Terfi: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Teklifteki pozisyon nasıl?")
                .font(.title2.weight(.bold))
                .foregroundColor(appTheme.textPrimary)
            Text("Terfi alarak mı yoksa aynı ünvanda mı gidiyorsunuz?")
                .font(.subheadline)
                .foregroundColor(appTheme.textSecondary)
            
            kartIcerik {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        secenekButon("Terfi alarak", secili: teklif.terfiIleMi == true) {
                            teklif.terfiIleMi = true
                        }
                        secenekButon("Aynı ünvanda", secili: teklif.terfiIleMi == false) {
                            teklif.terfiIleMi = false
                        }
                    }
                }
            }
        }
    }
    
    // Soru 4: Yılda kaç maaş — hem mevcut iş hem teklif için, 1–24 arası
    private var soru4MaasPeriyodu: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Yılda kaç maaş alınıyor?")
                .font(.title2.weight(.bold))
                .foregroundColor(appTheme.textPrimary)
            
            Text("Varsayılan 12. İstenirse 1–24 arası değiştirilebilir.")
                .font(.subheadline)
                .foregroundColor(appTheme.textSecondary)
            
            // Mevcut İş Yeri
            VStack(alignment: .leading, spacing: 12) {
                Text("Mevcut İş Yeri")
                    .font(.headline)
                    .foregroundColor(appTheme.textPrimary)
                maasPeriyoduAlani(value: $mevcutIs.maasPeriyodu)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(appTheme.listRowBackground)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(temaRengi.opacity(0.3), lineWidth: 1))
            )
            
            // Teklifte Bulunan İş Yeri
            VStack(alignment: .leading, spacing: 12) {
                Text("Teklifte Bulunan İş Yeri")
                    .font(.headline)
                    .foregroundColor(appTheme.textPrimary)
                maasPeriyoduAlani(value: $teklif.maasPeriyodu)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(appTheme.listRowBackground)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(temaRengi.opacity(0.3), lineWidth: 1))
            )
        }
    }
    
    private func maasPeriyoduAlani(value: Binding<Int>) -> some View {
        HStack(spacing: 16) {
            Text("Yılda")
                .foregroundColor(appTheme.textSecondary)
            TextField("12", value: value, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .frame(width: 56)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(appTheme.cardBackgroundSecondary)
                )
                .onChange(of: value.wrappedValue) { _, v in
                    let clamped = min(24, max(1, v))
                    if clamped != v { value.wrappedValue = clamped }
                }
            Text("maaş")
                .foregroundColor(appTheme.textSecondary)
            Stepper("", value: value, in: 1...24)
        }
    }
    
    private func kartIcerik<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(appTheme.listRowBackground)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(temaRengi.opacity(0.3), lineWidth: 1))
            )
    }
    
    private func secenekButon(_ title: String, secili: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(secili ? temaRengi : appTheme.cardBackgroundSecondary)
                .foregroundColor(secili ? .white : appTheme.textPrimary)
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Soru 5: Çalışma Modeli
    private var soru5CalismaModeli: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Çalışma modeli nedir?")
                .font(.title2.weight(.bold))
                .foregroundColor(appTheme.textPrimary)
            Text("Ofis, hibrit veya uzaktan çalışma.")
                .font(.subheadline)
                .foregroundColor(appTheme.textSecondary)
            
            kartIcerik {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Mevcut İş Yeri").font(.headline).foregroundColor(appTheme.textPrimary)
                    calismaModeliAlani(data: mevcutIs)
                }
            }
            kartIcerik {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Teklifte Bulunan İş Yeri").font(.headline).foregroundColor(appTheme.textPrimary)
                    calismaModeliAlani(data: teklif)
                }
            }
        }
    }
    
    private func calismaModeliAlani(data: YanHakVerisi) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ForEach(CalismaModeli.allCases, id: \.self) { m in
                    secenekButon(m.rawValue, secili: data.calismaModeli == m) {
                        data.calismaModeli = m
                        if m == .hibrit && data.hibritGunSayisi == nil { data.hibritGunSayisi = 2 }
                    }
                }
            }
            if data.calismaModeli == .hibrit {
                HStack(spacing: 16) {
                    Text("Haftada kaç gün ofis?").foregroundColor(appTheme.textSecondary)
                    TextField("2", value: Binding(
                        get: { data.hibritGunSayisi ?? 2 },
                        set: { data.hibritGunSayisi = min(5, max(1, $0)) }
                    ), format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 48)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 10).fill(appTheme.cardBackgroundSecondary))
                    .onChange(of: data.hibritGunSayisi ?? 2) { _, v in
                        data.hibritGunSayisi = min(5, max(1, v))
                    }
                    Text("gün").foregroundColor(appTheme.textSecondary)
                }
            }
        }
    }
    
    // MARK: - Soru 6: Yıllık İzin
    private var soru6YillikIzin: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Yıllık izin gün sayısı?")
                .font(.title2.weight(.bold))
                .foregroundColor(appTheme.textPrimary)
            
            kartIcerik {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Mevcut İş Yeri").font(.headline).foregroundColor(appTheme.textPrimary)
                    izinGunuAlani(value: $mevcutIs.yillikIzinGunu)
                }
            }
            kartIcerik {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Teklifte Bulunan İş Yeri").font(.headline).foregroundColor(appTheme.textPrimary)
                    izinGunuAlani(value: $teklif.yillikIzinGunu)
                }
            }
        }
    }
    
    private func izinGunuAlani(value: Binding<Int?>) -> some View {
        HStack(spacing: 16) {
            TextField("14", value: Binding(
                get: { value.wrappedValue ?? 14 },
                set: { value.wrappedValue = $0 > 0 ? min(365, $0) : nil }
            ), format: .number)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .frame(width: 64)
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 10).fill(appTheme.cardBackgroundSecondary))
            Text("gün").foregroundColor(appTheme.textSecondary)
        }
    }
    
    // MARK: - Soru 7: Telefon
    private var soru7Telefon: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Telefon veriliyor mu?")
                .font(.title2.weight(.bold))
                .foregroundColor(appTheme.textPrimary)
            
            kartIcerik {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Mevcut İş Yeri").font(.headline).foregroundColor(appTheme.textPrimary)
                    telefonAlani(data: mevcutIs)
                }
            }
            kartIcerik {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Teklifte Bulunan İş Yeri").font(.headline).foregroundColor(appTheme.textPrimary)
                    telefonAlani(data: teklif)
                }
            }
        }
    }
    
    private func telefonAlani(data: YanHakVerisi) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Button { data.telefonVeriliyor = true } label: {
                    Text("Evet").font(.subheadline).padding(.horizontal, 20).padding(.vertical, 12)
                        .background(data.telefonVeriliyor ? temaRengi : appTheme.cardBackgroundSecondary)
                        .foregroundColor(data.telefonVeriliyor ? .white : appTheme.textPrimary).cornerRadius(12)
                }.buttonStyle(.plain)
                Button { data.telefonVeriliyor = false; data.telefonFaturaKarsilaniyor = nil } label: {
                    Text("Hayır").font(.subheadline).padding(.horizontal, 20).padding(.vertical, 12)
                        .background(!data.telefonVeriliyor ? temaRengi : appTheme.cardBackgroundSecondary)
                        .foregroundColor(!data.telefonVeriliyor ? .white : appTheme.textPrimary).cornerRadius(12)
                }.buttonStyle(.plain)
            }
            if data.telefonVeriliyor {
                Text("Fatura karşılanıyor mu?")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(appTheme.textSecondary)
                HStack(spacing: 12) {
                    Button { data.telefonFaturaKarsilaniyor = true } label: {
                        Text("Evet").font(.subheadline).padding(.horizontal, 20).padding(.vertical, 12)
                            .background(data.telefonFaturaKarsilaniyor == true ? temaRengi : appTheme.cardBackgroundSecondary)
                            .foregroundColor(data.telefonFaturaKarsilaniyor == true ? .white : appTheme.textPrimary).cornerRadius(12)
                    }.buttonStyle(.plain)
                    Button { data.telefonFaturaKarsilaniyor = false } label: {
                        Text("Hayır").font(.subheadline).padding(.horizontal, 20).padding(.vertical, 12)
                            .background(data.telefonFaturaKarsilaniyor == false ? temaRengi : appTheme.cardBackgroundSecondary)
                            .foregroundColor(data.telefonFaturaKarsilaniyor == false ? .white : appTheme.textPrimary).cornerRadius(12)
                    }.buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Soru 8: Yıllık Prim/Bonus
    private var soru8PrimBonus: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Yıllık prim veya bonus tutarı?")
                .font(.title2.weight(.bold))
                .foregroundColor(appTheme.textPrimary)
            Text("Varsa tutarı girin (₺/yıl).")
                .font(.subheadline)
                .foregroundColor(appTheme.textSecondary)
            
            kartIcerik {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Mevcut İş Yeri").font(.headline).foregroundColor(appTheme.textPrimary)
                    KrediTextField(title: "Tutar (₺/yıl)", text: $mevcutPrimText, placeholder: "0", keyboardType: .decimalPad, formatThousands: true)
                        .onChange(of: mevcutPrimText) { _, v in mevcutIs.yillikPrimBonusTutar = parseFormattedNumber(v) }
                }
            }
            kartIcerik {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Teklifte Bulunan İş Yeri").font(.headline).foregroundColor(appTheme.textPrimary)
                    KrediTextField(title: "Tutar (₺/yıl)", text: $teklifPrimText, placeholder: "0", keyboardType: .decimalPad, formatThousands: true)
                        .onChange(of: teklifPrimText) { _, v in teklif.yillikPrimBonusTutar = parseFormattedNumber(v) }
                }
            }
        }
    }
    
    // MARK: - Soru 9: Sigorta Türü
    private var soru9Sigorta: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Sigorta türleri")
                .font(.title2.weight(.bold))
                .foregroundColor(appTheme.textPrimary)
            Text("İş yeri bazında işaretleyin. Varsa aile kapsamını belirtin.")
                .font(.subheadline)
                .foregroundColor(appTheme.textSecondary)
            
            kartIcerik {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Mevcut İş Yeri").font(.headline).foregroundColor(appTheme.textPrimary)
                    sigortaAlani(data: mevcutIs, gozDisText: $mevcutGozDisTutarText)
                }
            }
            kartIcerik {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Teklifte Bulunan İş Yeri").font(.headline).foregroundColor(appTheme.textPrimary)
                    sigortaAlani(data: teklif, gozDisText: $teklifGozDisTutarText)
                }
            }
        }
    }
    
    private func sigortaAlani(data: YanHakVerisi, gozDisText: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Tamamlayıcı Sağlık Sigortası", isOn: Binding(
                get: { data.tamamlayiciSaglikVar },
                set: { data.tamamlayiciSaglikVar = $0; if !$0 { data.tamamlayiciSaglikAileKapsami = false } }
            )).tint(temaRengi)
            if data.tamamlayiciSaglikVar {
                Toggle("Aileyi kapsıyor", isOn: Binding(get: { data.tamamlayiciSaglikAileKapsami }, set: { data.tamamlayiciSaglikAileKapsami = $0 })).tint(temaRengi)
            }
            Divider()
            Toggle("Özel Sağlık Sigortası", isOn: Binding(
                get: { data.ozelSaglikVar },
                set: { data.ozelSaglikVar = $0; if !$0 { data.ozelSaglikAileKapsami = false } }
            )).tint(temaRengi)
            if data.ozelSaglikVar {
                Toggle("Aileyi kapsıyor", isOn: Binding(get: { data.ozelSaglikAileKapsami }, set: { data.ozelSaglikAileKapsami = $0 })).tint(temaRengi)
            }
            Divider()
            Toggle("Göz, Diş vb. Teminatlar", isOn: Binding(
                get: { data.gozDisDestegiVar },
                set: { data.gozDisDestegiVar = $0; if !$0 { data.gozDisDestekTutar = nil } }
            )).tint(temaRengi)
            if data.gozDisDestegiVar {
                KrediTextField(title: "Tutar (₺/yıl)", text: gozDisText, placeholder: "0", keyboardType: .decimalPad, formatThousands: true)
                    .onChange(of: gozDisText.wrappedValue) { _, v in data.gozDisDestekTutar = parseFormattedNumber(v) }
            }
        }
    }
    
    // MARK: - Soru 10: Yemek
    private var soru10Yemek: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Yemek imkanı")
                .font(.title2.weight(.bold))
                .foregroundColor(appTheme.textPrimary)
            
            kartIcerik {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Mevcut İş Yeri").font(.headline).foregroundColor(appTheme.textPrimary)
                    yemekAlani(data: mevcutIs, yemekKartiText: $mevcutYemekKartiText)
                }
            }
            kartIcerik {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Teklifte Bulunan İş Yeri").font(.headline).foregroundColor(appTheme.textPrimary)
                    yemekAlani(data: teklif, yemekKartiText: $teklifYemekKartiText)
                }
            }
        }
    }
    
    private func yemekAlani(data: YanHakVerisi, yemekKartiText: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ForEach(YemekTipi.allCases, id: \.self) { t in
                    secenekButon(t.rawValue, secili: data.yemekTipi == t) {
                        data.yemekTipi = t
                        if t != .yemekKarti { data.yemekKartiGunlukTutar = nil }
                        if t != .yemekhane { data.yemekhaneKalitePuan = nil }
                    }
                }
                secenekButon("Yok", secili: data.yemekTipi == nil) {
                    data.yemekTipi = nil
                    data.yemekKartiGunlukTutar = nil
                    data.yemekhaneKalitePuan = nil
                }
            }
            if data.yemekTipi == .yemekKarti {
                KrediTextField(title: "Günlük yatan tutar (₺)", text: yemekKartiText, placeholder: "150", keyboardType: .decimalPad, formatThousands: true)
                    .onChange(of: yemekKartiText.wrappedValue) { _, v in data.yemekKartiGunlukTutar = parseFormattedNumber(v) }
            }
            if data.yemekTipi == .yemekhane {
                Text("Yemek kalitesi (5 üzerinden)")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(appTheme.textSecondary)
                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { puan in
                        Button {
                            data.yemekhaneKalitePuan = puan
                        } label: {
                            Text("\(puan)")
                                .font(.subheadline.weight(.semibold))
                                .frame(width: 36, height: 36)
                                .background(data.yemekhaneKalitePuan == puan ? temaRengi : appTheme.cardBackgroundSecondary)
                                .foregroundColor(data.yemekhaneKalitePuan == puan ? .white : appTheme.textPrimary)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    // MARK: - Soru 11: Ulaşım
    private var soru11Ulasim: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Ulaşım imkanı")
                .font(.title2.weight(.bold))
                .foregroundColor(appTheme.textPrimary)
            Text("Şirket araçı, servis, yol ücreti veya hiçbiri.")
                .font(.subheadline)
                .foregroundColor(appTheme.textSecondary)
            
            kartIcerik {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Mevcut İş Yeri").font(.headline).foregroundColor(appTheme.textPrimary)
                    ulasimAlani(data: mevcutIs, yolText: $mevcutYolUcretiText, yakitText: $mevcutYakitText)
                }
            }
            kartIcerik {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Teklifte Bulunan İş Yeri").font(.headline).foregroundColor(appTheme.textPrimary)
                    ulasimAlani(data: teklif, yolText: $teklifYolUcretiText, yakitText: $teklifYakitText)
                }
            }
        }
    }
    
    private func ulasimAlani(data: YanHakVerisi, yolText: Binding<String>, yakitText: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Ulaşım tipi")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(appTheme.textSecondary)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(UlasimTipi.allCases, id: \.self) { t in
                        Button {
                            data.ulasimTipi = t
                            if t != .yolUcreti { data.yolUcretiAylik = nil }
                            if t != .sirketAraci { data.sirketAraciYakitAylik = nil }
                        } label: {
                            Text(t.rawValue)
                                .font(.subheadline)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(data.ulasimTipi == t ? temaRengi : appTheme.cardBackgroundSecondary)
                                .foregroundColor(data.ulasimTipi == t ? .white : appTheme.textPrimary)
                                .cornerRadius(10)
                        }.buttonStyle(.plain)
                    }
                }
            }
            if data.ulasimTipi == .yolUcreti {
                KrediTextField(title: "Aylık yol ücreti (₺)", text: yolText, placeholder: "1.000", keyboardType: .decimalPad, formatThousands: true)
                    .onChange(of: yolText.wrappedValue) { _, v in data.yolUcretiAylik = parseFormattedNumber(v) }
            }
            if data.ulasimTipi == .sirketAraci {
                KrediTextField(title: "Aylık yakıt desteği (₺)", text: yakitText, placeholder: "2.000", keyboardType: .decimalPad, formatThousands: true)
                    .onChange(of: yakitText.wrappedValue) { _, v in data.sirketAraciYakitAylik = parseFormattedNumber(v) }
            }
            Text("Yolda harcanan süre (günlük gidiş-dönüş)")
                .font(.subheadline.weight(.medium))
                .foregroundColor(appTheme.textSecondary)
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Text("Saat").foregroundColor(appTheme.textSecondary)
                    Picker("", selection: Binding(
                        get: { data.yoldaSureSaat ?? 0 },
                        set: { data.yoldaSureSaat = $0 }
                    )) {
                        ForEach(0...5, id: \.self) { h in
                            Text("\(h)").tag(h)
                        }
                    }
                    .pickerStyle(.menu)
                }
                HStack(spacing: 8) {
                    Text("Dakika").foregroundColor(appTheme.textSecondary)
                    Picker("", selection: Binding(
                        get: { data.yoldaSureDakika ?? 0 },
                        set: { data.yoldaSureDakika = $0 }
                    )) {
                        ForEach(0..<60, id: \.self) { m in
                            Text("\(m)").tag(m)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
        }
    }
    
    // MARK: - Soru 12: İnternet, Elektrik vb.
    private var soru12InternetElektrik: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("İnternet, elektrik vb. destekler")
                .font(.title2.weight(.bold))
                .foregroundColor(appTheme.textPrimary)
            Text("Veriliyorsa toplam tutarı girin.")
                .font(.subheadline)
                .foregroundColor(appTheme.textSecondary)
            
            kartIcerik {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Mevcut İş Yeri").font(.headline).foregroundColor(appTheme.textPrimary)
                    internetDestekAlani(data: mevcutIs, text: $mevcutInternetText)
                }
            }
            kartIcerik {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Teklifte Bulunan İş Yeri").font(.headline).foregroundColor(appTheme.textPrimary)
                    internetDestekAlani(data: teklif, text: $teklifInternetText)
                }
            }
        }
    }
    
    private func internetDestekAlani(data: YanHakVerisi, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Button { data.internetElektrikDestekVar = true } label: {
                    Text("Veriliyor").font(.subheadline).padding(.horizontal, 20).padding(.vertical, 12)
                        .background(data.internetElektrikDestekVar ? temaRengi : appTheme.cardBackgroundSecondary)
                        .foregroundColor(data.internetElektrikDestekVar ? .white : appTheme.textPrimary).cornerRadius(12)
                }.buttonStyle(.plain)
                Button { data.internetElektrikDestekVar = false; data.internetElektrikToplamTutar = nil } label: {
                    Text("Verilmiyor").font(.subheadline).padding(.horizontal, 20).padding(.vertical, 12)
                        .background(!data.internetElektrikDestekVar ? temaRengi : appTheme.cardBackgroundSecondary)
                        .foregroundColor(!data.internetElektrikDestekVar ? .white : appTheme.textPrimary).cornerRadius(12)
                }.buttonStyle(.plain)
            }
            if data.internetElektrikDestekVar {
                KrediTextField(title: "Toplam tutar (₺/ay)", text: text, placeholder: "500", keyboardType: .decimalPad, formatThousands: true)
                    .onChange(of: text.wrappedValue) { _, v in data.internetElektrikToplamTutar = parseFormattedNumber(v) }
            }
        }
    }
    
    // MARK: - Örnek veri doldur
    private func ornekDoldur() {
        // Mevcut İş Yeri
        mevcutIs.brutMaas = 75000
        mevcutUcretText = formatNumberGoster(75000)
        mevcutIs.ucretBrutMu = true
        mevcutIs.mevcutIsYil = 5
        mevcutIs.terfiIleMi = nil
        mevcutIs.maasPeriyodu = 12
        mevcutIs.calismaModeli = .hibrit
        mevcutIs.hibritGunSayisi = 3
        mevcutIs.yillikIzinGunu = 14
        mevcutIs.telefonVeriliyor = true
        mevcutIs.telefonFaturaKarsilaniyor = true
        mevcutIs.yillikPrimBonusTutar = 15000
        mevcutPrimText = formatNumberGoster(15000)
        mevcutIs.tamamlayiciSaglikVar = true
        mevcutIs.tamamlayiciSaglikAileKapsami = false
        mevcutIs.ozelSaglikVar = false
        mevcutIs.gozDisDestegiVar = true
        mevcutIs.gozDisDestekTutar = 3000
        mevcutGozDisTutarText = formatNumberGoster(3000)
        mevcutIs.yemekTipi = .yemekhane
        mevcutIs.yemekhaneKalitePuan = 4
        mevcutIs.ulasimTipi = .servis
        mevcutIs.yoldaSureSaat = 1
        mevcutIs.yoldaSureDakika = 30
        mevcutIs.internetElektrikDestekVar = true
        mevcutIs.internetElektrikToplamTutar = 300
        mevcutInternetText = formatNumberGoster(300)
        
        // Teklifte Bulunan İş Yeri
        teklif.brutMaas = 95000
        teklifUcretText = formatNumberGoster(95000)
        teklif.ucretBrutMu = true
        teklif.terfiIleMi = true
        teklif.maasPeriyodu = 14
        teklif.calismaModeli = .remote
        teklif.yillikIzinGunu = 20
        teklif.telefonVeriliyor = true
        teklif.telefonFaturaKarsilaniyor = false
        teklif.yillikPrimBonusTutar = 25000
        teklifPrimText = formatNumberGoster(25000)
        teklif.tamamlayiciSaglikVar = true
        teklif.tamamlayiciSaglikAileKapsami = true
        teklif.ozelSaglikVar = true
        teklif.ozelSaglikAileKapsami = false
        teklif.gozDisDestegiVar = true
        teklif.gozDisDestekTutar = 5000
        teklifGozDisTutarText = formatNumberGoster(5000)
        teklif.yemekTipi = .yemekKarti
        teklif.yemekKartiGunlukTutar = 200
        teklifYemekKartiText = formatNumberGoster(200)
        teklif.ulasimTipi = .yolUcreti
        teklif.yolUcretiAylik = 1500
        teklifYolUcretiText = formatNumberGoster(1500)
        teklif.yoldaSureSaat = 0
        teklif.yoldaSureDakika = 15
        teklif.internetElektrikDestekVar = true
        teklif.internetElektrikToplamTutar = 500
        teklifInternetText = formatNumberGoster(500)
    }
    
    // MARK: - Karşılaştırma Formu
    private var karşılaştırmaFormu: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 0) {
                Button {
                    withAnimation { akisTamamlandi = false }
                } label: {
                    Label("Formu Düzenle", systemImage: "pencil")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(appTheme.listRowBackground)
                        .foregroundColor(temaRengi)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                
                // API Anahtarı (boşsa göster)
                if groqAPIKey.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Groq API Anahtarı")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(appTheme.textSecondary)
                        Text("AI yorumu almak için Groq Console'dan API anahtarı alın: console.groq.com")
                            .font(.caption)
                            .foregroundColor(appTheme.textSecondary)
                        SecureField("API anahtarınızı girin", text: $groqAPIKeyGecici)
                            .textContentType(.password)
                            .autocapitalization(.none)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 10).fill(appTheme.cardBackgroundSecondary))
                        Button("Kaydet") {
                            groqAPIKey = groqAPIKeyGecici.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(temaRengi)
                    }
                    .padding(20)
                    .background(RoundedRectangle(cornerRadius: 16).fill(appTheme.listRowBackground))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
                
                // AI Desteği Al — dashboard gömülü olarak devam eder (yeni pencere açılmaz)
                Button {
                    withAnimation { raporGosteriliyor = true }
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("AI Desteği Al")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(temaRengi)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                
                // AI Yorumu veya hata
            if let hata = aiYorumHata {
                    Text(hata)
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.red.opacity(0.1)))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                }
                if let yorum = aiYorumText {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AI Değerlendirmesi")
                            .font(.headline)
                            .foregroundColor(appTheme.textPrimary)
                        Text(yorum)
                            .font(.body)
                            .foregroundColor(appTheme.textPrimary)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 16).fill(appTheme.listRowBackground).overlay(RoundedRectangle(cornerRadius: 16).stroke(temaRengi.opacity(0.5), lineWidth: 1)))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
                
                // Tüm Detaylar — hızlı erişim butonu (özetin üstünde)
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) { detayAccordionAcik.toggle() }
                } label: {
                    HStack {
                        Text("Tüm Detaylar")
                            .font(AppTypography.headline)
                            .foregroundColor(appTheme.textPrimary)
                        Spacer()
                        Image(systemName: detayAccordionAcik ? "chevron.up" : "chevron.down")
                            .foregroundColor(temaRengi)
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(appTheme.listRowBackground))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)

                // Aylık net maaş karşılaştırması (çizgi grafik, büyütülmüş, ince çizgi)
                InlineMonthlyNetChart(current: mevcutIs.aylikNetMaaslar, offer: teklif.aylikNetMaaslar)
                    .environmentObject(appTheme)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)

                // Prim dahil yıllık toplam alanı
                VStack(alignment: .leading, spacing: 8) {
                    Text("Prim Dahil Yıllık Toplam (Net)")
                        .font(AppTypography.subheadline)
                        .foregroundColor(appTheme.textSecondary)
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Mevcut")
                                .font(AppTypography.caption1)
                                .foregroundColor(appTheme.textSecondary)
                            Text(FinanceFormatter.currencyString(mevcutIs.primDahilYillikToplam))
                                .font(AppTypography.amountMedium)
                                .monospacedDigit()
                                .foregroundColor(appTheme.textPrimary)
                        }
                        Spacer()
                        VStack(alignment: .leading) {
                            Text("Teklif")
                                .font(AppTypography.caption1)
                                .foregroundColor(appTheme.textSecondary)
                            Text(FinanceFormatter.currencyString(teklif.primDahilYillikToplam))
                                .font(AppTypography.amountMedium)
                                .monospacedDigit()
                                .foregroundColor(appTheme.textPrimary)
                        }
                        Spacer()
                        let deltaPrim = teklif.primDahilYillikToplam - mevcutIs.primDahilYillikToplam
                        VStack(alignment: .leading) {
                            Text("Fark")
                                .font(AppTypography.caption1)
                                .foregroundColor(appTheme.textSecondary)
                            Text("\(deltaPrim >= 0 ? "+" : "")\(FinanceFormatter.currencyString(deltaPrim))")
                                .font(AppTypography.amountMedium)
                                .monospacedDigit()
                                .foregroundColor(deltaPrim >= 0 ? Color(hex: "16A34A") : Color(hex: "EF4444"))
                        }
                    }
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 12).fill(appTheme.listRowBackground))
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

                // Özet kartı (ön planda)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Özet")
                        .font(AppTypography.headline)
                        .foregroundColor(appTheme.textPrimary)
                    karsilastirmaSatir("Ücret (₺/ay)", mevcut: "\(formatNumberGoster(mevcutIs.brutMaas)) (\(mevcutIs.ucretBrutMu ? "Brüt" : "Net"))", teklif: "\(formatNumberGoster(teklif.brutMaas)) (\(teklif.ucretBrutMu ? "Brüt" : "Net"))")
                    karsilastirmaSatir("Yıllık net maaş (₺)", mevcut: mevcutIs.yillikNetMaas > 0 ? formatNumberGoster(mevcutIs.yillikNetMaas) : "—", teklif: teklif.yillikNetMaas > 0 ? formatNumberGoster(teklif.yillikNetMaas) : "—")
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 20).fill(appTheme.listRowBackground).overlay(RoundedRectangle(cornerRadius: 20).stroke(temaRengi.opacity(0.3), lineWidth: 1)))
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                
                // Detay accordion
                VStack(alignment: .leading, spacing: 0) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) { detayAccordionAcik.toggle() }
                    } label: {
                        HStack {
                            Text("Tüm Detaylar")
                                .font(AppTypography.headline)
                                .foregroundColor(appTheme.textPrimary)
                            Spacer()
                            Image(systemName: detayAccordionAcik ? "chevron.up" : "chevron.down")
                                .font(AppTypography.footnote.weight(.semibold))
                                .foregroundColor(temaRengi)
                        }
                        .padding(20)
                        .background(RoundedRectangle(cornerRadius: 16).fill(appTheme.listRowBackground))
                    }
                    .buttonStyle(.plain)
                    
                    if detayAccordionAcik {
                        VStack(spacing: 0) {
                            karsilastirmaSatir("Mevcut işte çalışma süresi", mevcut: mevcutIs.mevcutIsYil.map { "\($0) yıl" } ?? "—", teklif: "—")
                            karsilastirmaSatir("Terfi / Aynı ünvan", mevcut: "—", teklif: teklif.terfiIleMi == true ? "Terfi alarak" : (teklif.terfiIleMi == false ? "Aynı ünvanda" : "—"))
                            karsilastirmaSatir("Yılda kaç maaş", mevcut: "\(mevcutIs.maasPeriyodu)", teklif: "\(teklif.maasPeriyodu)")
                            karsilastirmaSatir("Çalışma modeli", mevcut: mevcutIs.calismaModeli?.rawValue ?? "—", teklif: teklif.calismaModeli?.rawValue ?? "—")
                            karsilastirmaSatir("Hibrit gün (haftalık)", mevcut: mevcutIs.hibritGunSayisi.map { "\($0) gün" } ?? "—", teklif: teklif.hibritGunSayisi.map { "\($0) gün" } ?? "—")
                            karsilastirmaSatir("Yıllık izin", mevcut: mevcutIs.yillikIzinGunu.map { "\($0) gün" } ?? "—", teklif: teklif.yillikIzinGunu.map { "\($0) gün" } ?? "—")
                            karsilastirmaSatir("Telefon", mevcut: mevcutIs.telefonVeriliyor ? "Evet\(mevcutIs.telefonFaturaKarsilaniyor == true ? ", fatura karşılanıyor" : (mevcutIs.telefonFaturaKarsilaniyor == false ? ", fatura karşılanmıyor" : ""))" : "Hayır", teklif: teklif.telefonVeriliyor ? "Evet\(teklif.telefonFaturaKarsilaniyor == true ? ", fatura karşılanıyor" : (teklif.telefonFaturaKarsilaniyor == false ? ", fatura karşılanmıyor" : ""))" : "Hayır")
                            karsilastirmaSatir("Yıllık prim/bonus (₺)", mevcut: mevcutIs.yillikPrimBonusTutar.map { formatNumberGoster($0) } ?? "—", teklif: teklif.yillikPrimBonusTutar.map { formatNumberGoster($0) } ?? "—")
                            karsilastirmaSatir("Tamamlayıcı sağlık", mevcut: formatSigorta(mevcutIs.tamamlayiciSaglikVar, aile: mevcutIs.tamamlayiciSaglikAileKapsami), teklif: formatSigorta(teklif.tamamlayiciSaglikVar, aile: teklif.tamamlayiciSaglikAileKapsami))
                            karsilastirmaSatir("Özel sağlık", mevcut: formatSigorta(mevcutIs.ozelSaglikVar, aile: mevcutIs.ozelSaglikAileKapsami), teklif: formatSigorta(teklif.ozelSaglikVar, aile: teklif.ozelSaglikAileKapsami))
                            karsilastirmaSatir("Göz, Diş vb. Teminatlar (₺/yıl)", mevcut: mevcutIs.gozDisDestegiVar ? (mevcutIs.gozDisDestekTutar.map { formatNumberGoster($0) } ?? "—") : "—", teklif: teklif.gozDisDestegiVar ? (teklif.gozDisDestekTutar.map { formatNumberGoster($0) } ?? "—") : "—")
                            karsilastirmaSatir("Yemek", mevcut: formatYemek(mevcutIs), teklif: formatYemek(teklif))
                            karsilastirmaSatir("Ulaşım", mevcut: formatUlasim(mevcutIs), teklif: formatUlasim(teklif))
                            karsilastirmaSatir("Yolda geçen süre", mevcut: formatYoldaSure(mevcutIs), teklif: formatYoldaSure(teklif))
                            karsilastirmaSatir("İnternet, elektrik vb.", mevcut: mevcutIs.internetElektrikDestekVar ? "\(formatNumberGoster(mevcutIs.internetElektrikToplamTutar ?? 0)) ₺/ay" : "Yok", teklif: teklif.internetElektrikDestekVar ? "\(formatNumberGoster(teklif.internetElektrikToplamTutar ?? 0)) ₺/ay" : "Yok")
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                
                // Gömülü dashboard (AI Desteği Al tıklanınca)
                    if raporGosteriliyor {
                    Divider().padding(.vertical, 8)
                    // Inline Salary comparison summary (monthly net) — avoids external dependency
                    let currentMonthly = mevcutIs.yillikNetMaas / 12
                    let offeredMonthly = teklif.yillikNetMaas / 12
                    let maxVal = max(currentMonthly, offeredMonthly, 1)
                    VStack(spacing: 12) {
                        HStack(alignment: .bottom, spacing: 24) {
                            VStack(spacing: 8) {
                                Text(FinanceFormatter.currencyString(currentMonthly))
                                    .font(AppTypography.amountLarge)
                                    .foregroundColor(appTheme.textPrimary)
                                    .monospacedDigit()
                                GeometryReader { geo in
                                    let h = geo.size.height
                                    let barH = CGFloat(currentMonthly / maxVal) * h
                                    VStack { Spacer(); RoundedRectangle(cornerRadius: 8).fill(appTheme.cardBackgroundSecondary).frame(height: max(6, barH)).overlay(RoundedRectangle(cornerRadius: 8).stroke(appTheme.cardStroke.opacity(0.12))) }
                                }
                                .frame(height: 120)
                                Text("Mevcut").font(AppTypography.subheadline).foregroundColor(appTheme.textSecondary)
                            }
                            .frame(maxWidth: .infinity)

                            VStack(spacing: 8) {
                                Text(FinanceFormatter.currencyString(offeredMonthly))
                                    .font(AppTypography.amountLarge)
                                    .foregroundColor(appTheme.textPrimary)
                                    .monospacedDigit()
                                GeometryReader { geo in
                                    let h = geo.size.height
                                    let barH = CGFloat(offeredMonthly / maxVal) * h
                                    VStack { Spacer(); RoundedRectangle(cornerRadius: 8).fill(Color(hex: "3B82F6")).frame(height: max(8, barH * 1.03)).shadow(color: Color(hex: "3B82F6").opacity(0.18), radius: 6, x: 0, y: 4) }
                                }
                                .frame(height: 120)
                                Text("Teklif").font(AppTypography.subheadline).foregroundColor(appTheme.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .frame(maxWidth: .infinity)

                        // Difference box
                        HStack {
                            let diffMonthly = offeredMonthly - currentMonthly
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Yıllık Toplam Fark").font(AppTypography.subheadline).foregroundColor(appTheme.textSecondary)
                                let suffix = diffMonthly >= 0 ? "Artış" : "Azalış"
                                Text("\(FinanceFormatter.currencyString(abs(diffMonthly * 12))). \(suffix)")
                                    .font(AppTypography.amountMedium)
                                    .foregroundColor(diffMonthly >= 0 ? Color(hex: "16A34A") : Color(hex: "EF4444"))
                                    .monospacedDigit()
                            }
                            Spacer()
                            Text(String(format: "%+.1f%%", (offeredMonthly - currentMonthly) / maxVal * 100))
                                .font(AppTypography.subheadline)
                                .foregroundColor(appTheme.textSecondary)
                        }
                        .padding(12)
                        .modifier(PremiumCardModifier())
                    }
                    .padding(16)
                    .background(appTheme.cardBackground)
                    .cornerRadius(14)
                    .padding(.horizontal, 4)
                    // Detailed AI report below
                    YanHakRaporView(mevcutIs: mevcutIs, teklif: teklif, embedded: true)
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .clipped()
                        .environmentObject(appTheme)
                    
                    // (Resmi Tatiller removed from this screen — accessible via top "Resmi Tatiller" sekmesi)

                    Button {
                        yanHakKaydet()
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text(duzenlenenKayit != nil ? "Güncellemeyi Kaydet" : "Kaydet")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(temaRengi)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                    
                    if kaydetBasarili {
                        Text("Kaydedildi")
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "22C55E"))
                            .padding(.top, 4)
                    }
                }
            }
            .padding(20)
            .frame(minWidth: 0, maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func karsilastirmaSatir(_ baslik: String, mevcut: String, teklif: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(baslik)
                .font(.subheadline.weight(.medium))
                .foregroundColor(appTheme.textSecondary)
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Mevcut İş Yeri")
                        .font(.caption2)
                        .foregroundColor(appTheme.textSecondary)
                    Text(mevcut.isEmpty ? "—" : mevcut)
                        .font(.subheadline)
                        .foregroundColor(appTheme.textPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                }
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(appTheme.listRowBackground)
                .cornerRadius(12)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Teklifte Bulunan İş Yeri")
                        .font(.caption2)
                        .foregroundColor(appTheme.textSecondary)
                    Text(teklif.isEmpty ? "—" : teklif)
                        .font(.subheadline)
                        .foregroundColor(appTheme.textPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                }
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(appTheme.listRowBackground)
                .cornerRadius(12)
            }
        }
        .padding(.vertical, 6)
        .frame(minWidth: 0, maxWidth: .infinity)
    }
    
    private func formatSigorta(_ varMi: Bool, aile: Bool) -> String {
        varMi ? (aile ? "Var, aileyi kapsıyor" : "Var") : "Yok"
    }
    
    private func formatYemek(_ d: YanHakVerisi) -> String {
        switch d.yemekTipi {
        case .yemekhane: return "Yemekhane\(d.yemekhaneKalitePuan.map { ", \($0)/5 kalite" } ?? "")"
        case .yemekKarti: return "Yemek kartı\(d.yemekKartiGunlukTutar.map { ", \(formatNumberGoster($0)) ₺/gün" } ?? "")"
        case .none: return "Yok"
        }
    }
    
    private func formatUlasim(_ d: YanHakVerisi) -> String {
        guard let t = d.ulasimTipi else { return "—" }
        switch t {
        case .yolUcreti: return "Yol ücreti\(d.yolUcretiAylik.map { ", \(formatNumberGoster($0)) ₺/ay" } ?? "")"
        case .sirketAraci: return "Şirket araçı\(d.sirketAraciYakitAylik.map { ", \(formatNumberGoster($0)) ₺/ay yakıt" } ?? "")"
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
    
    private func yanHakKaydet() {
        guard let mevcutKopya = mevcutIs.kopyala(), let teklifKopya = teklif.kopyala() else { return }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.locale = Locale(identifier: "tr_TR")
        let ad = duzenlenenKayit?.name ?? "Analiz \(formatter.string(from: Date()))"
        let kayit = YanHakKayit(
            id: duzenlenenKayit?.id ?? UUID(),
            name: ad,
            createdAt: duzenlenenKayit?.createdAt ?? Date(),
            updatedAt: Date(),
            mevcutIs: mevcutKopya,
            teklif: teklifKopya
        )
        yanHakKayitStore.kaydet(kayit)
        kaydetBasarili = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            kaydetBasarili = false
        }
    }
    
    private func loadKayit(_ kayit: YanHakKayit) {
        mevcutIs.brutMaas = kayit.mevcutIs.brutMaas
        mevcutIs.ucretBrutMu = kayit.mevcutIs.ucretBrutMu
        mevcutIs.maasPeriyodu = kayit.mevcutIs.maasPeriyodu
        mevcutIs.mevcutIsYil = kayit.mevcutIs.mevcutIsYil
        mevcutIs.terfiIleMi = kayit.mevcutIs.terfiIleMi
        mevcutIs.calismaModeli = kayit.mevcutIs.calismaModeli
        mevcutIs.hibritGunSayisi = kayit.mevcutIs.hibritGunSayisi
        mevcutIs.yillikIzinGunu = kayit.mevcutIs.yillikIzinGunu
        mevcutIs.telefonVeriliyor = kayit.mevcutIs.telefonVeriliyor
        mevcutIs.telefonFaturaKarsilaniyor = kayit.mevcutIs.telefonFaturaKarsilaniyor
        mevcutIs.yillikPrimBonusTutar = kayit.mevcutIs.yillikPrimBonusTutar
        mevcutIs.tamamlayiciSaglikVar = kayit.mevcutIs.tamamlayiciSaglikVar
        mevcutIs.tamamlayiciSaglikAileKapsami = kayit.mevcutIs.tamamlayiciSaglikAileKapsami
        mevcutIs.ozelSaglikVar = kayit.mevcutIs.ozelSaglikVar
        mevcutIs.ozelSaglikAileKapsami = kayit.mevcutIs.ozelSaglikAileKapsami
        mevcutIs.gozDisDestegiVar = kayit.mevcutIs.gozDisDestegiVar
        mevcutIs.gozDisDestekTutar = kayit.mevcutIs.gozDisDestekTutar
        mevcutIs.yemekTipi = kayit.mevcutIs.yemekTipi
        mevcutIs.yemekKartiGunlukTutar = kayit.mevcutIs.yemekKartiGunlukTutar
        mevcutIs.yemekhaneKalitePuan = kayit.mevcutIs.yemekhaneKalitePuan
        mevcutIs.ulasimTipi = kayit.mevcutIs.ulasimTipi
        mevcutIs.yolUcretiAylik = kayit.mevcutIs.yolUcretiAylik
        mevcutIs.sirketAraciYakitAylik = kayit.mevcutIs.sirketAraciYakitAylik
        mevcutIs.yoldaSureSaat = kayit.mevcutIs.yoldaSureSaat
        mevcutIs.yoldaSureDakika = kayit.mevcutIs.yoldaSureDakika
        mevcutIs.internetElektrikDestekVar = kayit.mevcutIs.internetElektrikDestekVar
        mevcutIs.internetElektrikToplamTutar = kayit.mevcutIs.internetElektrikToplamTutar
        teklif.brutMaas = kayit.teklif.brutMaas
        teklif.ucretBrutMu = kayit.teklif.ucretBrutMu
        teklif.maasPeriyodu = kayit.teklif.maasPeriyodu
        teklif.terfiIleMi = kayit.teklif.terfiIleMi
        teklif.calismaModeli = kayit.teklif.calismaModeli
        teklif.hibritGunSayisi = kayit.teklif.hibritGunSayisi
        teklif.yillikIzinGunu = kayit.teklif.yillikIzinGunu
        teklif.telefonVeriliyor = kayit.teklif.telefonVeriliyor
        teklif.telefonFaturaKarsilaniyor = kayit.teklif.telefonFaturaKarsilaniyor
        teklif.yillikPrimBonusTutar = kayit.teklif.yillikPrimBonusTutar
        teklif.tamamlayiciSaglikVar = kayit.teklif.tamamlayiciSaglikVar
        teklif.tamamlayiciSaglikAileKapsami = kayit.teklif.tamamlayiciSaglikAileKapsami
        teklif.ozelSaglikVar = kayit.teklif.ozelSaglikVar
        teklif.ozelSaglikAileKapsami = kayit.teklif.ozelSaglikAileKapsami
        teklif.gozDisDestegiVar = kayit.teklif.gozDisDestegiVar
        teklif.gozDisDestekTutar = kayit.teklif.gozDisDestekTutar
        teklif.yemekTipi = kayit.teklif.yemekTipi
        teklif.yemekKartiGunlukTutar = kayit.teklif.yemekKartiGunlukTutar
        teklif.yemekhaneKalitePuan = kayit.teklif.yemekhaneKalitePuan
        teklif.ulasimTipi = kayit.teklif.ulasimTipi
        teklif.yolUcretiAylik = kayit.teklif.yolUcretiAylik
        teklif.sirketAraciYakitAylik = kayit.teklif.sirketAraciYakitAylik
        teklif.yoldaSureSaat = kayit.teklif.yoldaSureSaat
        teklif.yoldaSureDakika = kayit.teklif.yoldaSureDakika
        teklif.internetElektrikDestekVar = kayit.teklif.internetElektrikDestekVar
        teklif.internetElektrikToplamTutar = kayit.teklif.internetElektrikToplamTutar
        mevcutUcretText = formatNumberGoster(mevcutIs.brutMaas)
        teklifUcretText = formatNumberGoster(teklif.brutMaas)
        mevcutPrimText = mevcutIs.yillikPrimBonusTutar.map { formatNumberGoster($0) } ?? ""
        teklifPrimText = teklif.yillikPrimBonusTutar.map { formatNumberGoster($0) } ?? ""
        mevcutYemekKartiText = mevcutIs.yemekKartiGunlukTutar.map { formatNumberGoster($0) } ?? ""
        teklifYemekKartiText = teklif.yemekKartiGunlukTutar.map { formatNumberGoster($0) } ?? ""
        mevcutYolUcretiText = mevcutIs.yolUcretiAylik.map { formatNumberGoster($0) } ?? ""
        teklifYolUcretiText = teklif.yolUcretiAylik.map { formatNumberGoster($0) } ?? ""
        mevcutYakitText = mevcutIs.sirketAraciYakitAylik.map { formatNumberGoster($0) } ?? ""
        teklifYakitText = teklif.sirketAraciYakitAylik.map { formatNumberGoster($0) } ?? ""
        mevcutInternetText = mevcutIs.internetElektrikToplamTutar.map { formatNumberGoster($0) } ?? ""
        teklifInternetText = teklif.internetElektrikToplamTutar.map { formatNumberGoster($0) } ?? ""
        mevcutGozDisTutarText = mevcutIs.gozDisDestekTutar.map { formatNumberGoster($0) } ?? ""
        teklifGozDisTutarText = teklif.gozDisDestekTutar.map { formatNumberGoster($0) } ?? ""
        akisTamamlandi = true
        raporGosteriliyor = true
    }
    
    private func aiYorumAl() async {
        aiYorumHata = nil
        aiYorumText = nil
        aiYorumLoading = true
        
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
}

 
 

// Local compact calendar for YanHakAnaliziView (keeps this file self-contained)
fileprivate struct YearCalendarForYanHak: View {
    @EnvironmentObject var appTheme: AppTheme
    @State private var year: Int = 2026
    private let years = [2026, 2027, 2028]
    private let calendar = Calendar.current

    private func nationalHolidays(year: Int) -> [DateComponents] {
        return [
            DateComponents(year: year, month: 1, day: 1),
            DateComponents(year: year, month: 4, day: 23),
            DateComponents(year: year, month: 5, day: 1),
            DateComponents(year: year, month: 5, day: 19),
            DateComponents(year: year, month: 7, day: 15),
            DateComponents(year: year, month: 8, day: 30),
            DateComponents(year: year, month: 10, day: 29)
        ]
    }

    private func religiousRanges(year: Int) -> [ClosedRange<Date>] {
        func r(_ y: Int, _ m1: Int, _ d1: Int, _ m2: Int, _ d2: Int) -> ClosedRange<Date>? {
            if let s = calendar.date(from: DateComponents(year: y, month: m1, day: d1)),
               let e = calendar.date(from: DateComponents(year: y, month: m2, day: d2)) {
                return s...e
            }
            return nil
        }
        switch year {
        case 2026:
            return [r(2026,3,20,3,22), r(2026,5,27,5,30)].compactMap { $0 }
        case 2027:
            return [r(2027,3,9,3,11), r(2027,5,16,5,19)].compactMap { $0 }
        case 2028:
            return [r(2028,2,27,2,29), r(2028,5,5,5,8)].compactMap { $0 }
        default:
            return []
        }
    }

    private func isHoliday(_ date: Date) -> Bool {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        for nh in nationalHolidays(year: year) {
            if nh.year == comps.year && nh.month == comps.month && nh.day == comps.day { return true }
        }
        for range in religiousRanges(year: year) {
            if range.contains(date) { return true }
        }
        return false
    }

    private func isWeekend(_ date: Date) -> Bool {
        let wd = calendar.component(.weekday, from: date)
        return wd == 1 || wd == 7
    }

    var body: some View {
        ZStack {
            (appTheme.isLight ? appTheme.background : Color.black).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(String(year))
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.red)
                        Spacer()
                        Picker("", selection: $year) {
                            ForEach(years, id: \.self) { y in Text(String(y)).tag(y) }
                        }
                        .pickerStyle(.menu)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 8)

                    let cols = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
                    LazyVGrid(columns: cols, spacing: 12) {
                        ForEach(1...12, id: \.self) { month in
                            MonthCompactLocal(year: year, month: month, isHoliday: isHoliday(_:), isWeekend: isWeekend(_:))
                                .environmentObject(appTheme)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 20)
                }
            }
        }
    }
}

fileprivate struct MonthCompactLocal: View {
    @EnvironmentObject var appTheme: AppTheme
    let year: Int
    let month: Int
    let isHoliday: (Date) -> Bool
    let isWeekend: (Date) -> Bool
    private let cal = Calendar.current

    private var monthName: String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "tr_TR")
        return df.shortMonthSymbols[month - 1]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(monthName)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)
            CompactDaysLocal(year: year, month: month, isHoliday: isHoliday, isWeekend: isWeekend)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
    }
}

fileprivate struct CompactDaysLocal: View {
    let year: Int
    let month: Int
    let isHoliday: (Date) -> Bool
    let isWeekend: (Date) -> Bool
    @EnvironmentObject var appTheme: AppTheme
    private let cal = Calendar.current

    var body: some View {
        let first = cal.date(from: DateComponents(year: year, month: month, day: 1))!
        let range = cal.range(of: .day, in: .month, for: first)!
        let weekdayOffset = (cal.component(.weekday, from: first) + 6) % 7

        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 6) {
            ForEach(0..<weekdayOffset, id: \.self) { _ in
                Text(" ").font(.system(size: 9)).frame(minHeight: 10)
            }
            ForEach(range, id: \.self) { day in
                let date = cal.date(from: DateComponents(year: year, month: month, day: day))!
                let holiday = isHoliday(date)
                let weekend = isWeekend(date)
                ZStack {
                    if holiday {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 20, height: 20)
                    }
                    Text("\(day)")
                        .font(.system(size: 11, weight: weekend ? .bold : .regular))
                        .foregroundColor(holiday ? .white : .white.opacity(0.92))
                }
                .frame(minWidth: 18, minHeight: 18)
            }
        }
    }
}

// Inline simple monthly net comparison chart to avoid Swift Charts dependency
fileprivate struct InlineMonthlyNetChart: View {
    @EnvironmentObject var appTheme: AppTheme
    let current: [Double]
    let offer: [Double]
    private let months = ["Oca","Şub","Mar","Nis","May","Haz","Tem","Ağu","Eyl","Eki","Kas","Ara"]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h: CGFloat = 200
            let paddingX: CGFloat = 24
            let chartW = max(0, w - paddingX * 2)
            let maxVal = max((current.max() ?? 1), (offer.max() ?? 1), 1)

            ZStack {
                // horizontal grid lines
                VStack(spacing: 0) {
                    ForEach(0..<3) { _ in
                        Rectangle()
                            .fill(appTheme.cardStroke.opacity(0.06))
                            .frame(height: 1)
                        Spacer()
                    }
                }
                .padding(.vertical, 20)

                // current line
                Path { path in
                    for (i, val) in current.enumerated() {
                        let x = paddingX + (chartW) * CGFloat(i) / 11.0
                        let y = 20 + (h - 40) * (1 - CGFloat(val / maxVal))
                        if i == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }
                .stroke(appTheme.cardBackgroundSecondary.opacity(0.95), lineWidth: 1.0)

                // offer line
                Path { path in
                    for (i, val) in offer.enumerated() {
                        let x = paddingX + (chartW) * CGFloat(i) / 11.0
                        let y = 20 + (h - 40) * (1 - CGFloat(val / maxVal))
                        if i == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 1.0, lineCap: .round, lineJoin: .round))
                .shadow(color: Color.accentColor.opacity(0.12), radius: 6, x: 0, y: 4)

                // month labels
                HStack(spacing: 0) {
                    ForEach(0..<12, id: \.self) { i in
                        Text(months[i])
                            .font(AppTypography.caption1.italic())
                            .foregroundColor(appTheme.textSecondary)
                            .rotationEffect(.degrees(-20))
                            .frame(width: chartW/12, alignment: .center)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 4)
            }
            .frame(height: h)
        }
        .frame(height: 200)
    }
}

#Preview {
    NavigationStack {
        YanHakAnaliziView()
            .environmentObject(AppTheme())
            .environmentObject(YanHakKayitStore.shared)
    }
}
