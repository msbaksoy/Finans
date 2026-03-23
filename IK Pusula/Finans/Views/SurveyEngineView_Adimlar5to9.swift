// ================================================================
// SurveyEngineView_Adimlar5to9.swift — ADIM 5-9 YENİDEN TASARIM
// ================================================================
// step5_Ulasim, step6_Yemek, step7_Saglik, step8_BES, step9_YillikIzin
// + chipButon, tutarGirisAlan (extension); ikiSecenekButon/besSecenekButon
// SurveyEngineView içinde kalır, çakışma yok.
// ================================================================

import SwiftUI

// MARK: - ─── TEMEL TASARIM FELSEFESİ ──────────────────────────────
//
// Seçenekler → yatay CHIP veya 3'lü grid.
// Koşullu genişleme → seçeneklerin HEMEN ALTINDA, aynı kart içinde.
// ─────────────────────────────────────────────────────────────────

// MARK: - ADIM 5: ULAŞIM ──────────────────────────────────────────

extension SurveyEngineView {

    var step5_Ulasim: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                adimBaslik("İşe nasıl gidiyorsunuz?", renk: Color(hex: "F59E0B"))
                    .padding(.horizontal, 2)

                ulasimSatiriKarti(isCurrent: true)
                ulasimSatiriKarti(isCurrent: false)

                Color.clear.frame(height: 110)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
        .scrollDismissesKeyboard(.immediately)
    }

    private func ulasimKalitesiKod(_ tip: String) -> String {
        switch tip {
        case "Toplu Ulaşım": return "Toplu Taşıma"
        case "Şahsi Araç": return "Kendi Aracım"
        default: return tip
        }
    }

    @ViewBuilder
    private func ulasimSatiriKarti(isCurrent: Bool) -> some View {
        let renk = isCurrent ? viewModel.currentCompanyColor : viewModel.offerCompanyColor
        let baslik = isCurrent ? mevcutSirketLabel : teklifSirketLabel
        let secilenTip = isCurrent ? mevcutUlasimTipi : teklifUlasimTipi
        let calisma = isCurrent ? mevcutCalismaModeli : teklifCalismaModeli
        let isRemote = calisma.localizedCaseInsensitiveContains("uzaktan") || calisma == "Remote"
        let aracVar = isCurrent ? mevcutRemoteAracTahsisVarMi : teklifRemoteAracTahsisVarMi

        VStack(alignment: .leading, spacing: 12) {
            sirketBolumBasligi(baslik, renk: renk)

            if isRemote {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Şirket araç veya yakıt desteği veriyor mu?")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        chipButon(metin: "Evet, veriyor", secili: aracVar == true, renk: renk) {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            if isCurrent { mevcutRemoteAracTahsisVarMi = true; viewModel.draft.mevcutSirketAraciVarMi = true }
                            else { teklifRemoteAracTahsisVarMi = true; viewModel.draft.teklifSirketAraciVarMi = true }
                        }
                        chipButon(metin: "Hayır, yok", secili: aracVar == false, renk: .gray) {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            if isCurrent { mevcutRemoteAracTahsisVarMi = false; viewModel.draft.mevcutSirketAraciVarMi = false }
                            else { teklifRemoteAracTahsisVarMi = false; viewModel.draft.teklifSirketAraciVarMi = false }
                        }
                    }

                    if aracVar == true {
                        VStack(alignment: .leading, spacing: 8) {
                            AracSegmentSecimButonu(
                                selection: isCurrent ? $mevcutAracSegment : $teklifAracSegment,
                                accentColor: renk
                            ).environmentObject(appTheme)

                            Text("Yakıt desteği var mı?")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            let yakitVar = isCurrent ? mevcutRemoteYakitDestegiVarMi : teklifRemoteYakitDestegiVarMi
                            HStack(spacing: 8) {
                                chipButon(metin: "Yakıt var", secili: yakitVar == true, renk: renk) {
                                    if isCurrent { mevcutRemoteYakitDestegiVarMi = true }
                                    else { teklifRemoteYakitDestegiVarMi = true }
                                }
                                chipButon(metin: "Yok", secili: yakitVar == false, renk: .gray) {
                                    if isCurrent { mevcutRemoteYakitDestegiVarMi = false; mevcutRemoteYakitAylikTL = "" }
                                    else { teklifRemoteYakitDestegiVarMi = false; teklifRemoteYakitAylikTL = "" }
                                }
                            }

                            if yakitVar == true {
                                tutarGirisAlan(
                                    placeholder: "₺ Aylık yakıt tutarı",
                                    text: isCurrent ? $mevcutRemoteYakitAylikTL : $teklifRemoteYakitAylikTL,
                                    renk: renk
                                )
                            }
                        }
                        .padding(12)
                        .background(renk.opacity(0.05))
                        .cornerRadius(12)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
            } else {
                let secenek: [(String, String)] = [
                    ("car.fill",      "Şirket Aracı"),
                    ("car.circle",    "Şahsi Araç"),
                    ("tram.fill",     "Toplu Ulaşım"),
                    ("bus.fill",      "Servis"),
                    ("figure.walk",   "Yürüyerek"),
                ]

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(secenek, id: \.1) { ikon, tip in
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                withAnimation(.spring(response: 0.3)) {
                                    if isCurrent {
                                        mevcutUlasimTipi = tip
                                        viewModel.draft.mevcutSirketAraciVarMi = (tip == "Şirket Aracı")
                                        if tip != "Şirket Aracı" { viewModel.draft.mevcutUlasimKalitesi = ulasimKalitesiKod(tip) }
                                    } else {
                                        teklifUlasimTipi = tip
                                        viewModel.draft.teklifSirketAraciVarMi = (tip == "Şirket Aracı")
                                        if tip != "Şirket Aracı" { viewModel.draft.teklifUlasimKalitesi = ulasimKalitesiKod(tip) }
                                    }
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: ikon)
                                        .font(.system(size: 13, weight: .semibold))
                                    Text(tip)
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundColor(secilenTip == tip ? .white : renk)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(secilenTip == tip ? renk : renk.opacity(0.1))
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(secilenTip == tip ? renk : renk.opacity(0.2), lineWidth: 1.5))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }

                if !secilenTip.isEmpty && secilenTip != "Yürüyerek" && secilenTip != "Servis" {
                    VStack(alignment: .leading, spacing: 12) {
                        switch secilenTip {
                        case "Şirket Aracı":
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Hangi segment araç?")
                                    .font(.caption.bold())
                                    .foregroundColor(renk)
                                AracSegmentSecimButonu(
                                    selection: isCurrent ? $mevcutAracSegment : $teklifAracSegment,
                                    accentColor: renk
                                ).environmentObject(appTheme)
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Yakıt masrafı?")
                                    .font(.caption.bold())
                                    .foregroundColor(renk)
                                HStack(spacing: 8) {
                                    let yKarsilayan = isCurrent ? mevcutYakitKarsilayan : teklifYakitKarsilayan
                                    chipButon(metin: "Şirket karşılıyor", secili: yKarsilayan == "Şirket", renk: renk) {
                                        if isCurrent { mevcutYakitKarsilayan = "Şirket" }
                                        else { teklifYakitKarsilayan = "Şirket" }
                                    }
                                    chipButon(metin: "Cebimden", secili: yKarsilayan == "Ben", renk: renk) {
                                        if isCurrent { mevcutYakitKarsilayan = "Ben" }
                                        else { teklifYakitKarsilayan = "Ben" }
                                    }
                                }
                                let yKarsilayan = isCurrent ? mevcutYakitKarsilayan : teklifYakitKarsilayan
                                if yKarsilayan == "Şirket" {
                                    tutarGirisAlan(
                                        placeholder: "₺ Aylık limit (boş = limitsiz)",
                                        text: isCurrent ? $mevcutYakitTutari : $teklifYakitTutari,
                                        renk: renk
                                    )
                                }
                            }

                        case "Toplu Ulaşım":
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Kim karşılıyor?")
                                    .font(.caption.bold())
                                    .foregroundColor(renk)
                                HStack(spacing: 8) {
                                    let kars = isCurrent ? mevcutTopluKarsilayan : teklifTopluKarsilayan
                                    chipButon(metin: "Şirket ödüyor", secili: kars == "Şirket", renk: renk) {
                                        if isCurrent { mevcutTopluKarsilayan = "Şirket" }
                                        else { teklifTopluKarsilayan = "Şirket" }
                                    }
                                    chipButon(metin: "Ben ödüyorum", secili: kars == "Ben", renk: renk) {
                                        if isCurrent { mevcutTopluKarsilayan = "Ben" }
                                        else { teklifTopluKarsilayan = "Ben" }
                                    }
                                }
                                let kars = isCurrent ? mevcutTopluKarsilayan : teklifTopluKarsilayan
                                if !kars.isEmpty {
                                    tutarGirisAlan(
                                        placeholder: "₺ Aylık ulaşım tutarı",
                                        text: isCurrent ? $mevcutTopluTutar : $teklifTopluTutar,
                                        renk: renk
                                    )
                                }
                            }

                        case "Şahsi Araç":
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Yakıt / otopark gideri kim karşılıyor?")
                                    .font(.caption.bold())
                                    .foregroundColor(renk)
                                HStack(spacing: 8) {
                                    let kars = isCurrent ? mevcutYakitKarsilayan : teklifYakitKarsilayan
                                    chipButon(metin: "Şirket karşılıyor", secili: kars == "Şirket", renk: renk) {
                                        if isCurrent { mevcutYakitKarsilayan = "Şirket" }
                                        else { teklifYakitKarsilayan = "Şirket" }
                                    }
                                    chipButon(metin: "Ben karşılıyorum", secili: kars == "Ben", renk: renk) {
                                        if isCurrent { mevcutYakitKarsilayan = "Ben" }
                                        else { teklifYakitKarsilayan = "Ben" }
                                    }
                                }
                                tutarGirisAlan(
                                    placeholder: "₺ Aylık toplam gider (yakıt + otopark)",
                                    text: isCurrent ? $mevcutYakitTutari : $teklifYakitTutari,
                                    renk: renk
                                )
                            }

                        default:
                            EmptyView()
                        }
                    }
                    .padding(14)
                    .background(renk.opacity(0.05))
                    .cornerRadius(14)
                    .transition(.move(edge: .top).combined(with: .opacity))
                } else if secilenTip == "Servis" {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(appTheme.successColor)
                            .font(.subheadline)
                        Text("Ücretsiz şirket servisi — ek bilgi gerekmez.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(appTheme.successColor.opacity(0.06))
                    .cornerRadius(12)
                    .transition(.opacity)
                } else if secilenTip == "Yürüyerek" {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(appTheme.successColor)
                            .font(.subheadline)
                        Text("Harika! Ulaşım masrafın yok.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(appTheme.successColor.opacity(0.06))
                    .cornerRadius(12)
                    .transition(.opacity)
                }
            }
        }
        .padding(16)
        .background(renk.opacity(0.04))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(renk.opacity(0.14), lineWidth: 1))
        .animation(.spring(response: 0.35), value: secilenTip)
        .animation(.spring(response: 0.3), value: isCurrent ? mevcutRemoteAracTahsisVarMi : teklifRemoteAracTahsisVarMi)
    }
}

// MARK: - ADIM 6: YEMEK ───────────────────────────────────────────

extension SurveyEngineView {

    var step6_Yemek: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                adimBaslik("Yemek imkânı nasıl?", renk: Color(hex: "EF4444"))
                    .padding(.horizontal, 2)

                yemekSatiriKarti(isCurrent: true)
                yemekSatiriKarti(isCurrent: false)

                Color.clear.frame(height: 110)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
        .scrollDismissesKeyboard(.immediately)
    }

    @ViewBuilder
    private func yemekSatiriKarti(isCurrent: Bool) -> some View {
        let renk = isCurrent ? viewModel.currentCompanyColor : viewModel.offerCompanyColor
        let baslik = isCurrent ? mevcutSirketLabel : teklifSirketLabel
        let secilenTip = isCurrent ? mevcutYemekTipi : teklifYemekTipi
        let yemekPuan = isCurrent ? mevcutYemekPuan : teklifYemekPuan

        VStack(alignment: .leading, spacing: 12) {
            sirketBolumBasligi(baslik, renk: renk)

            HStack(spacing: 8) {
                let secenekler: [(String, String)] = [
                    ("fork.knife",        "Yemekhane"),
                    ("creditcard.fill",   "Yemek Kartı"),
                    ("xmark.circle.fill", "Yok"),
                ]
                ForEach(secenekler, id: \.1) { ikon, tip in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.3)) {
                            if isCurrent { mevcutYemekTipi = tip; viewModel.draft.mevcutYemekTipi = tip }
                            else { teklifYemekTipi = tip; viewModel.draft.teklifYemekTipi = tip }
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: ikon).font(.system(size: 12, weight: .semibold))
                            Text(tip).font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(secilenTip == tip ? .white : renk)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 10)
                        .background(secilenTip == tip ? renk : renk.opacity(0.09))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(secilenTip == tip ? renk : renk.opacity(0.18), lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(secilenTip == tip ? 0.97 : 1)
                    .animation(.spring(response: 0.2), value: secilenTip)
                }
                Spacer()
            }

            if secilenTip == "Yemekhane" {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Yemekhane kalitesi nasıl?")
                        .font(.caption.bold())
                        .foregroundColor(renk)
                    HStack(spacing: 10) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= yemekPuan ? "star.fill" : "star")
                                .font(.system(size: 26))
                                .foregroundColor(star <= yemekPuan ? .yellow : Color.gray.opacity(0.3))
                                .onTapGesture {
                                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                                    if isCurrent { mevcutYemekPuan = star; viewModel.draft.mevcutYemekLezzetYildiz = star }
                                    else { teklifYemekPuan = star; viewModel.draft.teklifYemekLezzetYildiz = star }
                                }
                        }
                        Spacer()
                        Text(yemekPuanMetni(yemekPuan))
                            .font(.caption.bold())
                            .foregroundColor(.yellow)
                    }
                }
                .padding(12)
                .background(Color.yellow.opacity(0.06))
                .cornerRadius(12)
                .transition(.move(edge: .top).combined(with: .opacity))

            } else if secilenTip == "Yemek Kartı" {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Günlük kart tutarı ne kadar?")
                        .font(.caption.bold())
                        .foregroundColor(renk)
                    tutarGirisAlan(
                        placeholder: "₺ Günlük tutar (örn: 400)",
                        text: isCurrent ? $mevcutGunlukYemek : $teklifGunlukYemek,
                        renk: renk
                    )
                    Text("Aylık yaklaşık: ₺\(hesaplaAylikYemek(isCurrent: isCurrent))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(renk.opacity(0.05))
                .cornerRadius(12)
                .transition(.move(edge: .top).combined(with: .opacity))

            } else if secilenTip == "Yok" {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill").foregroundColor(.orange).font(.subheadline)
                    Text("Yemek desteği olmadığında aylık ~₺6.000–8.000 cebinden çıkabilir.")
                        .font(.caption).foregroundColor(.secondary)
                }
                .padding(10)
                .background(Color.orange.opacity(0.06))
                .cornerRadius(10)
                .transition(.opacity)
            }
        }
        .padding(16)
        .background(renk.opacity(0.04))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(renk.opacity(0.14), lineWidth: 1))
        .animation(.spring(response: 0.35), value: secilenTip)
    }

    private func yemekPuanMetni(_ puan: Int) -> String {
        ["", "Kötü", "Orta", "İyi", "Çok İyi", "Mükemmel"][safe: puan] ?? ""
    }

    private func hesaplaAylikYemek(isCurrent: Bool) -> String {
        let str = isCurrent ? mevcutGunlukYemek : teklifGunlukYemek
        guard let gunluk = Double(str.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")) else { return "—" }
        let aylik = Int(gunluk * 22)
        let f = NumberFormatter(); f.numberStyle = .decimal; f.locale = Locale(identifier: "tr_TR")
        return f.string(from: NSNumber(value: aylik)) ?? "\(aylik)"
    }
}

// MARK: - ADIM 7: SAĞLIK ──────────────────────────────────────────

extension SurveyEngineView {

    var step7_Saglik: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                adimBaslik("Sağlık sigortası durumu", renk: Color(hex: "10B981"))
                    .padding(.horizontal, 2)

                saglikSatiriKarti(isCurrent: true)
                saglikSatiriKarti(isCurrent: false)

                Color.clear.frame(height: 110)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
        .onAppear {
            let m = viewModel.draft.mevcutSigortaYararlananKisiSayisi
            let t = viewModel.draft.teklifSigortaYararlananKisiSayisi
            if m > 1 { mevcutSaglikAile = true; mevcutSaglikKisiSayisi = min(10, max(2, m)) }
            if t > 1 { teklifSaglikAile = true; teklifSaglikKisiSayisi = min(10, max(2, t)) }
        }
    }

    @ViewBuilder
    private func saglikSatiriKarti(isCurrent: Bool) -> some View {
        let renk = isCurrent ? viewModel.currentCompanyColor : viewModel.offerCompanyColor
        let baslik = isCurrent ? mevcutSirketLabel : teklifSirketLabel
        let secilenTip = isCurrent ? mevcutSaglikTipi : teklifSaglikTipi
        let saglikAile = isCurrent ? mevcutSaglikAile : teklifSaglikAile
        let kisiSayisi = isCurrent ? mevcutSaglikKisiSayisi : teklifSaglikKisiSayisi

        VStack(alignment: .leading, spacing: 12) {
            sirketBolumBasligi(baslik, renk: renk)

            let secenekler: [(String, String, String)] = [
                ("cross.case.fill", "ÖSS", "Özel Sağlık"),
                ("shield.fill",     "TSS", "Tamamlayıcı"),
                ("xmark.circle",    "Yok", "Sigorta Yok"),
            ]

            HStack(spacing: 8) {
                ForEach(secenekler, id: \.1) { ikon, kod, altMetin in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.3)) {
                            if isCurrent {
                                mevcutSaglikTipi = kod
                                viewModel.draft.mevcutSigortaTipi = saglikDraftKod(kod)
                            } else {
                                teklifSaglikTipi = kod
                                viewModel.draft.teklifSigortaTipi = saglikDraftKod(kod)
                            }
                        }
                    } label: {
                        VStack(spacing: 5) {
                            Image(systemName: ikon)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(secilenTip == kod ? .white : renk)
                            Text(kod)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(secilenTip == kod ? .white : appTheme.textPrimary)
                            Text(altMetin)
                                .font(.system(size: 10))
                                .foregroundColor(secilenTip == kod ? .white.opacity(0.75) : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(secilenTip == kod ? renk : renk.opacity(0.07))
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(secilenTip == kod ? renk : renk.opacity(0.15), lineWidth: 1.5))
                        .scaleEffect(secilenTip == kod ? 0.97 : 1)
                        .animation(.spring(response: 0.2), value: secilenTip)
                    }
                    .buttonStyle(.plain)
                }
            }

            if secilenTip == "ÖSS" || secilenTip == "TSS" {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Kapsam")
                        .font(.caption.bold())
                        .foregroundColor(renk)

                    HStack(spacing: 8) {
                        chipButon(metin: "👤  Sadece Ben", secili: saglikAile == false, renk: renk) {
                            withAnimation {
                                if isCurrent {
                                    mevcutSaglikAile = false
                                    viewModel.draft.mevcutSigortaYararlananKisiSayisi = 1
                                } else {
                                    teklifSaglikAile = false
                                    viewModel.draft.teklifSigortaYararlananKisiSayisi = 1
                                }
                            }
                        }
                        chipButon(metin: "👨‍👩‍👧  Ailemi Kapsıyor", secili: saglikAile == true, renk: appTheme.successColor) {
                            withAnimation {
                                if isCurrent { mevcutSaglikAile = true }
                                else { teklifSaglikAile = true }
                            }
                        }
                    }

                    if saglikAile == true {
                        HStack {
                            Text("Yararlanan kişi sayısı")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            HStack(spacing: 16) {
                                Button {
                                    let min2 = 2
                                    if isCurrent, mevcutSaglikKisiSayisi > min2 {
                                        mevcutSaglikKisiSayisi -= 1
                                        viewModel.draft.mevcutSigortaYararlananKisiSayisi = mevcutSaglikKisiSayisi
                                    } else if !isCurrent, teklifSaglikKisiSayisi > min2 {
                                        teklifSaglikKisiSayisi -= 1
                                        viewModel.draft.teklifSigortaYararlananKisiSayisi = teklifSaglikKisiSayisi
                                    }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(renk.opacity(kisiSayisi > 2 ? 1 : 0.3))
                                }

                                Text("\(kisiSayisi)")
                                    .font(.title3.bold().monospacedDigit())
                                    .foregroundColor(appTheme.textPrimary)
                                    .frame(minWidth: 28, alignment: .center)
                                    .contentTransition(.numericText())

                                Button {
                                    if isCurrent, mevcutSaglikKisiSayisi < 10 {
                                        mevcutSaglikKisiSayisi += 1
                                        viewModel.draft.mevcutSigortaYararlananKisiSayisi = mevcutSaglikKisiSayisi
                                    } else if !isCurrent, teklifSaglikKisiSayisi < 10 {
                                        teklifSaglikKisiSayisi += 1
                                        viewModel.draft.teklifSigortaYararlananKisiSayisi = teklifSaglikKisiSayisi
                                    }
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(renk)
                                }
                            }
                        }
                        .padding(10)
                        .background(renk.opacity(0.06))
                        .cornerRadius(10)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .padding(12)
                .background(renk.opacity(0.05))
                .cornerRadius(12)
                .transition(.move(edge: .top).combined(with: .opacity))

            } else if secilenTip == "Yok" {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.subheadline)
                    Text("Sigorta yokken özel hastane masrafları direkt cebinden çıkar.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(10)
                .background(Color.orange.opacity(0.06))
                .cornerRadius(10)
                .transition(.opacity)
            }
        }
        .padding(16)
        .background(renk.opacity(0.04))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(renk.opacity(0.14), lineWidth: 1))
        .animation(.spring(response: 0.35), value: secilenTip)
        .animation(.spring(response: 0.3), value: saglikAile)
    }

    private func saglikDraftKod(_ kod: String) -> String {
        switch kod {
        case "ÖSS": return "Özel"
        case "TSS": return "Tamamlayıcı"
        default:    return "Yok"
        }
    }
}

// MARK: - ADIM 8: BES ─────────────────────────────────────────────

extension SurveyEngineView {

    var step8_BES: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                adimBaslik("BES şirket katkısı var mı?", renk: Color(hex: "8B5CF6"))
                    .padding(.horizontal, 2)

                HStack(alignment: .top, spacing: 14) {
                    besSatiriKarti(isCurrent: true)
                    besSatiriKarti(isCurrent: false)
                }

                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.caption)
                        .foregroundColor(Color(hex: "8B5CF6"))
                    Text("İşveren BES katkısı vergiden muaf bir kazanım — maaşınıza zam gibi etki eder.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(Color(hex: "8B5CF6").opacity(0.06))
                .cornerRadius(12)

                Color.clear.frame(height: 110)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
        .scrollDismissesKeyboard(.immediately)
    }

    @ViewBuilder
    private func besSatiriKarti(isCurrent: Bool) -> some View {
        let renk = isCurrent ? viewModel.currentCompanyColor : viewModel.offerCompanyColor
        let baslik = isCurrent ? mevcutSirketLabel : teklifSirketLabel
        let besVar = isCurrent ? mevcutBesVarMi : teklifBesVarMi

        VStack(alignment: .leading, spacing: 12) {
            Text(baslik)
                .font(.caption.bold())
                .foregroundColor(renk)
                .lineLimit(1)

            VStack(spacing: 8) {
                besSecenekButon(metin: "✓  Var", secili: besVar == true, renk: renk) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation {
                        if isCurrent { mevcutBesVarMi = true; viewModel.draft.mevcutBesVarMi = true }
                        else { teklifBesVarMi = true; viewModel.draft.teklifBesVarMi = true }
                    }
                }
                besSecenekButon(metin: "✗  Yok", secili: besVar == false, renk: Color.gray) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation {
                        if isCurrent { mevcutBesVarMi = false; viewModel.draft.mevcutBesVarMi = false }
                        else { teklifBesVarMi = false; viewModel.draft.teklifBesVarMi = false }
                    }
                }
            }

            if besVar == true {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Aylık katkı (₺)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    TextField("Tutar", text: isCurrent ? $mevcutBesTutar : $teklifBesTutar)
                        .keyboardType(.numberPad)
                        .focused($isInputActive)
                        .font(.headline)
                        .padding(10)
                        .background(renk.opacity(0.08))
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(renk.opacity(0.2), lineWidth: 1))
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(renk.opacity(0.04))
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(renk.opacity(0.14), lineWidth: 1))
        .animation(.spring(response: 0.3), value: besVar)
    }

    private func besSecenekButon(metin: String, secili: Bool, renk: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(metin)
                .font(.subheadline.bold())
                .foregroundColor(secili ? .white : appTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(secili ? (renk == Color.gray ? Color.gray : renk) : Color.gray.opacity(0.08))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(secili ? renk : Color.clear, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ADIM 9: YILLIK İZİN ─────────────────────────────────────

extension SurveyEngineView {

    var step9_YillikIzin: some View {
        VStack(alignment: .leading, spacing: 24) {
            adimBaslik("Yıllık izin gün sayısı", renk: Color(hex: "F59E0B"))
                .padding(.horizontal, 24)
                .padding(.top, 8)

            HStack(spacing: 14) {
                izinBuyukKarti(
                    baslik: mevcutSirketLabel,
                    renk: viewModel.currentCompanyColor,
                    gun: $mevcutYillikIzin
                )
                izinBuyukKarti(
                    baslik: teklifSirketLabel,
                    renk: viewModel.offerCompanyColor,
                    gun: $teklifYillikIzin
                )
            }
            .padding(.horizontal, 24)

            let fark = teklifYillikIzin - mevcutYillikIzin
            Group {
                if fark > 0 {
                    farkBanner(
                        ikon: "checkmark.circle.fill",
                        metin: "Yılda \(fark) gün daha fazla izin — değerli bir yaşam kalitesi kazanımı.",
                        renk: appTheme.successColor
                    )
                } else if fark < 0 {
                    farkBanner(
                        ikon: "minus.circle.fill",
                        metin: "Yılda \(abs(fark)) gün izin kaybı — maaş artışı bunu karşılıyor mu?",
                        renk: appTheme.warningColor
                    )
                } else {
                    farkBanner(
                        ikon: "equal.circle.fill",
                        metin: "Her iki işte de izin gün sayısı eşit.",
                        renk: appTheme.primaryAccent
                    )
                }
            }
            .padding(.horizontal, 24)
            .transition(.opacity)
            .animation(.spring(response: 0.4), value: fark)

            Spacer()
        }
        .onAppear {
            mevcutYillikIzin = viewModel.draft.mevcutYillikIzin
            teklifYillikIzin = viewModel.draft.teklifYillikIzin
        }
    }

    private func izinBuyukKarti(baslik: String, renk: Color, gun: Binding<Int>) -> some View {
        VStack(spacing: 12) {
            Text(baslik)
                .font(.caption.bold())
                .foregroundColor(renk)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(gun.wrappedValue)")
                .font(.system(size: 52, weight: .black, design: .rounded))
                .foregroundColor(renk)
                .frame(maxWidth: .infinity, alignment: .center)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3), value: gun.wrappedValue)

            Text("gün / yıl")
                .font(.caption)
                .foregroundColor(.secondary)

            Divider()

            HStack {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    if gun.wrappedValue > 0 { gun.wrappedValue -= 1 }
                } label: {
                    Image(systemName: "minus")
                        .font(.title3.bold())
                        .frame(width: 44, height: 44)
                        .background(gun.wrappedValue > 0 ? Color.gray.opacity(0.1) : Color.clear)
                        .clipShape(Circle())
                        .foregroundColor(gun.wrappedValue > 0 ? appTheme.textPrimary : Color.gray.opacity(0.3))
                }

                Spacer()

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    gun.wrappedValue += 1
                } label: {
                    Image(systemName: "plus")
                        .font(.title3.bold())
                        .frame(width: 44, height: 44)
                        .background(renk.opacity(0.12))
                        .clipShape(Circle())
                        .foregroundColor(renk)
                }
            }
        }
        .padding(16)
        .background(renk.opacity(0.05))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(renk.opacity(0.16), lineWidth: 1.5))
        .frame(maxWidth: .infinity)
    }

    private func farkBanner(ikon: String, metin: String, renk: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: ikon)
                .font(.subheadline)
                .foregroundColor(renk)
            Text(metin)
                .font(.subheadline)
                .foregroundColor(appTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(renk.opacity(0.08))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(renk.opacity(0.18), lineWidth: 1))
    }
}

// MARK: - Ortak Yardımcı Bileşenler ───────────────────────────────

extension SurveyEngineView {

    func chipButon(metin: String, secili: Bool, renk: Color, action: @escaping () -> Void) -> some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            Text(metin)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(secili ? .white : (renk == Color.gray ? appTheme.textPrimary : renk))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(secili ? (renk == Color.gray ? Color.gray : renk) : Color.gray.opacity(0.09))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(secili ? renk : Color.gray.opacity(0.2), lineWidth: 1.5))
                .scaleEffect(secili ? 0.97 : 1)
                .animation(.spring(response: 0.2), value: secili)
        }
        .buttonStyle(.plain)
    }

    func tutarGirisAlan(placeholder: String, text: Binding<String>, renk: Color) -> some View {
        HStack(spacing: 8) {
            Text("₺")
                .font(.headline.bold())
                .foregroundColor(renk)
            TextField(placeholder.replacingOccurrences(of: "₺ ", with: ""), text: text)
                .keyboardType(.numberPad)
                .focused($isInputActive)
                .font(.headline)
                .foregroundColor(appTheme.textPrimary)
        }
        .padding(12)
        .background(renk.opacity(0.06))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(renk.opacity(0.2), lineWidth: 1))
    }
}

// MARK: - Array safe subscript ────────────────────────────────────
private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
