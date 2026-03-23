import SwiftUI

struct KiyaslamaAnalysisView: View {
    @ObservedObject var viewModel: KariyerKiyaslamaViewModel
    @EnvironmentObject var appTheme: AppTheme
    var isReadOnly: Bool = false
    var isEditMode: Bool = false
    var onEditTapped: (() -> Void)? = nil
    var onFinish: () -> Void
    
    @State private var animasyonBasladi = false
    @State private var isAnalyzing = false
    @State private var isDeepDivePresented = false
    @State private var showDerinAnalizAfterDive = false
    @State private var showDerinAnalizSheet = false
    
    // Kullanıcının AI bilgilendirmesini onaylayıp onaylamadığını takip eder
    @AppStorage("aiConsentAccepted") private var aiConsentAccepted = false
    @State private var showAIConsentSheet = false
    
    var body: some View {
        let mevcutYalin = viewModel.calculateNet(isCurrent: true, includePrim: false)
        let teklifYalin = viewModel.calculateNet(isCurrent: false, includePrim: false)
        let yalinAylikFark = teklifYalin.aylikOrtalama - mevcutYalin.aylikOrtalama
        let yalinYuzde = mevcutYalin.aylikOrtalama > 0 ? (yalinAylikFark / mevcutYalin.aylikOrtalama) * 100 : 0
        
        let mevcutToplam = viewModel.calculateNet(isCurrent: true, includePrim: true)
        let teklifToplam = viewModel.calculateNet(isCurrent: false, includePrim: true)
        let toplamYillikFark = teklifToplam.yillikNet - mevcutToplam.yillikNet
        let toplamYuzde = mevcutToplam.yillikNet > 0 ? (toplamYillikFark / mevcutToplam.yillikNet) * 100 : 0
        let maxYillik = max(mevcutToplam.yillikNet, teklifToplam.yillikNet)
        
        let sirket1 = viewModel.draft.mevcutSirketAdi.isEmpty ? "Mevcut" : viewModel.draft.mevcutSirketAdi
        let sirket2 = viewModel.draft.teklifSirketAdi.isEmpty ? "Teklif" : viewModel.draft.teklifSirketAdi
        
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {

                // ==========================================
                // DERİN ANALİZ (EN ÜSTTE — GÖRÜNÜRLÜK)
                // ==========================================
                Button(action: { isDeepDivePresented = true }) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [Color(red: 0.1, green: 0.1, blue: 0.18), Color(red: 0.09, green: 0.13, blue: 0.24)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 48, height: 48)
                            Image(systemName: "sparkles")
                                .font(.title3.bold())
                                .foregroundColor(.yellow)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Derin Analiz Yap")
                                .font(.headline.bold())
                                .foregroundColor(appTheme.textPrimary)
                            Text("Araç, BES, izin, kıdem tazminatı ve daha fazlası")
                                .font(.caption)
                                .foregroundColor(appTheme.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.subheadline.bold())
                            .foregroundColor(appTheme.textSecondary)
                    }
                    .padding(16)
                    .background(appTheme.primaryAccent.opacity(0.08))
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.yellow.opacity(0.3), lineWidth: 1.5))
                    .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
                }
                .buttonStyle(.plain)
                .fullScreenCover(isPresented: $isDeepDivePresented, onDismiss: {
                    if showDerinAnalizAfterDive {
                        showDerinAnalizSheet = true
                    }
                    showDerinAnalizAfterDive = false
                }) {
                    DeepKiyaslamaAnalysisView(viewModel: viewModel, onClose: {
                        isDeepDivePresented = false
                    })
                    .environmentObject(appTheme)
                }
                .fullScreenCover(isPresented: $showDerinAnalizSheet) {
                    DeepKiyaslamaAnalysisView(viewModel: viewModel)
                        .environmentObject(appTheme)
                }

                // ==========================================
                // AŞAMA 1: SADECE SABİT MAAŞ (PRİMSİZ)
                // ==========================================
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        Image(systemName: "turkishlirasign.circle.fill").foregroundColor(appTheme.primaryAccent)
                        Text("1. Sabit Maaş Kıyaslaması").font(.headline).foregroundColor(appTheme.textPrimary)
                    }
                    HStack(spacing: 16) {
                        AylikKutu(sirket: sirket1, ortalama: mevcutYalin.aylikOrtalama, renk: viewModel.currentCompanyColor)
                        AylikKutu(sirket: sirket2, ortalama: teklifYalin.aylikOrtalama, renk: viewModel.offerCompanyColor)
                    }
                    let yalinArtis = yalinAylikFark > 0
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle.fill").foregroundColor(yalinArtis ? appTheme.successColor : appTheme.dangerColor)
                        JustifiedText(yalinAylikFark == 0
                            ? "İki şirketin prim hariç aylık net maaşı tamamen aynı."
                            : "Sadece net maaşları kıyasladığımızda cebine her ay %\(formatYuzde(abs(yalinYuzde))) oranında (\(formatPara(abs(yalinAylikFark)))) \(yalinArtis ? "daha fazla" : "daha az") nakit girecek.")
                    }
                }
                .padding(20).background(Color(uiColor: .systemBackground)).cornerRadius(20).shadow(color: .black.opacity(0.04), radius: 10)
                
                // ==========================================
                // AŞAMA 2: PRİM/BONUS DAHİL TOPLAM PAKET
                // ==========================================
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 8) {
                        Image(systemName: "chart.bar.fill").foregroundColor(appTheme.primaryAccent)
                        Text("2. Toplam Yıllık Paket (Primler Dahil)").font(.headline).foregroundColor(appTheme.textPrimary)
                    }
                    VStack(spacing: 24) {
                        PremiumBar(baslik: sirket1, deger: mevcutToplam.yillikNet, maxDeger: maxYillik, renk: viewModel.currentCompanyColor, animasyonBasladi: animasyonBasladi)
                        PremiumBar(baslik: sirket2, deger: teklifToplam.yillikNet, maxDeger: maxYillik, renk: viewModel.offerCompanyColor, animasyonBasladi: animasyonBasladi)
                    }
                    .padding(.top, 4)
                    Divider().padding(.vertical, 4)
                    let toplamArtis = toplamYillikFark > 0
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "banknote.fill").foregroundColor(toplamArtis ? appTheme.successColor : appTheme.dangerColor)
                        JustifiedText(toplamYillikFark == 0
                            ? "Yıllık toplam kazancında bir değişiklik olmuyor."
                            : "Prim ve bonusları da hesaba kattığımızda yıl sonunda toplam kazancın %\(formatYuzde(abs(toplamYuzde))) oranında (\(formatPara(abs(toplamYillikFark)))) \(toplamArtis ? "artmış" : "düşmüş") olacak.")
                    }
                }
                .padding(20).background(Color(uiColor: .systemBackground)).cornerRadius(20).shadow(color: .black.opacity(0.04), radius: 10)
                
                // ==========================================
                // AŞAMA 3: ÇALIŞMA MODELİ VE YAŞAM KALİTESİ
                // ==========================================
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        Image(systemName: "house.and.flag.fill").foregroundColor(appTheme.primaryAccent)
                        Text("3. Çalışma Modeli ve Yaşam Kalitesi").font(.headline).foregroundColor(appTheme.textPrimary)
                    }
                    HStack {
                        ModelKutusu(baslik: sirket1, model: viewModel.draft.mevcutCalismaModeli, gun: viewModel.draft.mevcutOfisGunSayisi, renk: viewModel.currentCompanyColor)
                        ModelKutusu(baslik: sirket2, model: viewModel.draft.teklifCalismaModeli, gun: viewModel.draft.teklifOfisGunSayisi, renk: viewModel.offerCompanyColor)
                    }
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "sparkles").font(.title2).foregroundColor(appTheme.warningColor)
                        JustifiedText(calismaModeliYorumu())
                    }
                    .padding(16).background(appTheme.warningColor.opacity(0.1)).cornerRadius(12)
                }
                .padding(20).background(Color(uiColor: .systemBackground)).cornerRadius(20).shadow(color: .black.opacity(0.04), radius: 10)
                
                // ==========================================
                // AŞAMA 4: KARİYER STRATEJİSİ
                // ==========================================
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.right.square.fill").foregroundColor(appTheme.primaryAccent)
                        Text("4. Kariyer ve Unvan Stratejisi").font(.headline).foregroundColor(appTheme.textPrimary)
                    }
                    let kariyerYorumu = kariyerYorumuUret(mevcutNet: mevcutToplam.yillikNet, teklifNet: teklifToplam.yillikNet)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: kariyerYorumu.ikon).font(.title2).foregroundColor(kariyerYorumu.renk)
                            Text(kariyerYorumu.baslik).font(.subheadline.bold()).foregroundColor(kariyerYorumu.renk)
                        }
                        JustifiedText(kariyerYorumu.metin)
                    }
                    .padding(16).background(kariyerYorumu.renk.opacity(0.08)).cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(kariyerYorumu.renk.opacity(0.2), lineWidth: 1))
                }
                .padding(20).background(Color(uiColor: .systemBackground)).cornerRadius(20).shadow(color: .black.opacity(0.04), radius: 10)
                
                // ==========================================
                // AŞAMA 5: YEMEK VE ESNEK BÜTÇE
                // ==========================================
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        Image(systemName: "takeoutbag.and.cup.and.straw.fill").foregroundColor(appTheme.primaryAccent)
                        Text("5. Yemek ve Esnek Bütçe").font(.headline).foregroundColor(appTheme.textPrimary)
                    }
                    let yemekYorumu = yemekYorumuUret()
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: yemekYorumu.ikon).font(.title2).foregroundColor(yemekYorumu.renk)
                            Text(yemekYorumu.baslik).font(.subheadline.bold()).foregroundColor(yemekYorumu.renk)
                        }
                        JustifiedText(yemekYorumu.metin)
                    }
                    .padding(16).background(yemekYorumu.renk.opacity(0.08)).cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(yemekYorumu.renk.opacity(0.2), lineWidth: 1))
                }
                .padding(20).background(Color(uiColor: .systemBackground)).cornerRadius(20).shadow(color: .black.opacity(0.04), radius: 10)
                
                // ==========================================
                // AŞAMA 6: SAĞLIK SİGORTASI
                // ==========================================
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        Image(systemName: "cross.case.fill").foregroundColor(appTheme.primaryAccent)
                        Text("6. Sağlık Sigortası Analizi").font(.headline).foregroundColor(appTheme.textPrimary)
                    }
                    let sigortaYorumu = sigortaYorumuUret()
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: sigortaYorumu.ikon).font(.title2).foregroundColor(sigortaYorumu.renk)
                            Text(sigortaYorumu.baslik).font(.subheadline.bold()).foregroundColor(sigortaYorumu.renk)
                        }
                        JustifiedText(sigortaYorumu.metin)
                    }
                    .padding(16).background(sigortaYorumu.renk.opacity(0.08)).cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(sigortaYorumu.renk.opacity(0.2), lineWidth: 1))
                }
                .padding(20).background(Color(uiColor: .systemBackground)).cornerRadius(20).shadow(color: .black.opacity(0.04), radius: 10)
                
                // ==========================================
                // AŞAMA 7: DETAYLI TABLO
                // ==========================================
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        Image(systemName: "list.bullet.clipboard.fill").foregroundColor(appTheme.primaryAccent)
                        Text("Detaylı Kıyaslama Tablosu").font(.headline).foregroundColor(appTheme.textPrimary)
                    }
                    VStack(spacing: 12) {
                        KiyasSatiri(baslik: "Günlük Yol Süresi",
                                    m1: viewModel.draft.mevcutYolSureDakika > 0 ? "\(viewModel.draft.mevcutYolSureDakika) dk" : "-",
                                    m2: viewModel.draft.teklifYolSureDakika > 0 ? "\(viewModel.draft.teklifYolSureDakika) dk" : "-")
                        KiyasSatiri(baslik: "Yemek İmkânı", m1: viewModel.draft.mevcutYemekTipi, m2: viewModel.draft.teklifYemekTipi)
                        KiyasSatiri(baslik: "Sağlık Sigortası", m1: viewModel.draft.mevcutSigortaTipi, m2: viewModel.draft.teklifSigortaTipi)
                    }
                }
                .padding(20).background(Color(uiColor: .systemBackground)).cornerRadius(20).shadow(color: .black.opacity(0.04), radius: 10)
                
                // ==========================================
                // AŞAMA 8: YAPAY ZEKA KARİYER KOÇU
                // ==========================================
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        Image(systemName: "brain.head.profile").foregroundColor(.purple)
                        Text("Yapay Zeka Kariyer Koçu").font(.headline).foregroundColor(appTheme.textPrimary)
                    }
                    
                    HStack(alignment: .center, spacing: 8) {
                        Text("Bu alan, yapay zekâ ile kariyer analizi üretir.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button {
                            showAIConsentSheet = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "info.circle")
                                Text("Bilgilerim nasıl kullanılıyor?")
                            }
                            .font(.caption2)
                        }
                    }
                    
                    if let analizSonucu = viewModel.aiHizliYorumu {
                        JustifiedText(analizSonucu)
                            .padding(16)
                            .background(Color.purple.opacity(0.08))
                            .cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.purple.opacity(0.2), lineWidth: 1))
                    } else if isAnalyzing {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                                .tint(.purple)
                            Text("Yapay zeka verilerini analiz edip sana özel bir kariyer stratejisi hazırlıyor...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(24)
                        .background(Color.purple.opacity(0.05))
                        .cornerRadius(16)
                    } else {
                        Button(action: {
                            if aiConsentAccepted {
                                Task { await fetchAIAnalysis() }
                            } else {
                                showAIConsentSheet = true
                            }
                        }) {
                            HStack {
                                Image(systemName: "sparkles")
                                Text("Bu Teklifi Yapay Zekaya Yorumlat").font(.subheadline.bold())
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(LinearGradient(colors: [Color.purple, Color.indigo], startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(16)
                            .shadow(color: .purple.opacity(0.3), radius: 6, y: 3)
                        }
                    }
                }
                .padding(20).background(Color(uiColor: .systemBackground)).cornerRadius(20).shadow(color: .black.opacity(0.04), radius: 10)

                // BİLGİLERİ DÜZENLE (sadece wizard akışında, form adımlarına geri dön)
                if !isReadOnly, let onEdit = onEditTapped {
                    Button(action: onEdit) {
                        HStack(spacing: 8) {
                            Image(systemName: "pencil.circle.fill").font(.title2)
                            Text("Bilgileri Düzenle").font(.headline.bold())
                        }
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(16)
                    }
                    .padding(.top, 4)
                }

                // BİTİR / GERİ DÖN / GÜNCELLE BUTONU
                Button(action: onFinish) {
                    Text(isReadOnly ? "Geri Dön" : (isEditMode ? "Güncelle ve Kapat" : "Analizi Kaydet ve Çık"))
                        .font(.headline.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(appTheme.primaryAccent)
                        .cornerRadius(16)
                        .shadow(color: appTheme.primaryAccent.opacity(0.3), radius: 8, y: 4)
                }
                .padding(.top, 10).padding(.bottom, 40)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .background(appTheme.backgroundMain.ignoresSafeArea())
        .sheet(isPresented: $showAIConsentSheet) {
            AIVerisiBilgilendirmeView {
                // Onaylandığında bayrağı kaydet ve isteniyorsa analizi tetikle
                aiConsentAccepted = true
                showAIConsentSheet = false
                Task { await fetchAIAnalysis() }
            } onCancel: {
                showAIConsentSheet = false
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                    animasyonBasladi = true
                }
            }
        }
    }
    
    // MARK: - Yapay Zeka Servisini Çağıran Fonksiyon
    private func fetchAIAnalysis() async {
        withAnimation { isAnalyzing = true }
        do {
            let mevcutNet = viewModel.calculateNet(isCurrent: true, includePrim: true).yillikNet
            let teklifNet = viewModel.calculateNet(isCurrent: false, includePrim: true).yillikNet
            let sonuc = try await OpenAIService.shared.fetchCareerAdvice(
                draft: viewModel.draft,
                mevcutYillikNet: mevcutNet,
                teklifYillikNet: teklifNet
            )
            withAnimation { viewModel.aiHizliYorumu = sonuc; isAnalyzing = false }
        } catch {
            withAnimation {
                viewModel.aiHizliYorumu = "Bağlantı hatası. Lütfen tekrar dene."
                isAnalyzing = false
            }
        }
    }
    
    // MARK: - Sağlık Sigortası Algoritması
    private func sigortaYorumuUret() -> (baslik: String, metin: String, ikon: String, renk: Color) {
        let mevcut = viewModel.draft.mevcutSigortaTipi
        let teklif = viewModel.draft.teklifSigortaTipi
        let mOzel = mevcut == "Özel"
        let mTamam = mevcut == "Tamamlayıcı"
        let mYok = mevcut == "Yok" || mevcut.isEmpty
        let tOzel = teklif == "Özel"
        let tTamam = teklif == "Tamamlayıcı"
        let tYok = teklif == "Yok" || teklif.isEmpty
        
        if mTamam && tOzel {
            return (baslik: "Kapsam Genişliyor (TSS'den ÖSS'ye)", metin: "Tamamlayıcı sigortadan Özel Sağlık Sigortasına (ÖSS) geçiş yapıyorsun. Bu, çok daha geniş anlaşmalı hastane ağı (A sınıfı hastaneler) ve daha yüksek teminatlar demektir. Ciddi bir yan hak kazanımı!", ikon: "staroflife.fill", renk: appTheme.successColor)
        } else if mOzel && tTamam {
            return (baslik: "Kapsam Daralması (ÖSS'den TSS'ye)", metin: "Özel Sağlık Sigortanı (ÖSS) bırakıp Tamamlayıcı Sağlık Sigortasına (TSS) geçiyorsun. Gidebileceğin hastane ağı ve teminat limitleri daralacaktır. Bunu finansal bir eksi olarak not etmelisin.", ikon: "exclamationmark.triangle.fill", renk: appTheme.warningColor)
        } else if mYok && tOzel {
            return (baslik: "Premium Yan Hak Kazanımı", metin: "Yeni şirketin Özel Sağlık Sigortası (ÖSS) sunuyor. Daha önce cebinden karşıladığın veya devlet hastanelerine bağımlı olduğun sağlık giderleri artık güvence altında. Çok değerli bir avantaj.", ikon: "staroflife.fill", renk: appTheme.successColor)
        } else if mYok && tTamam {
            return (baslik: "Güvenlik Ağı Kazanımı", metin: "Yeni şirketin Tamamlayıcı Sağlık Sigortası (TSS) sunuyor. Özel hastanelerde fark ücreti ödemeden tedavi olabilmek büyük bir maddi güvence ve konfor sağlayacaktır.", ikon: "shield.fill", renk: appTheme.successColor)
        } else if !mYok && tYok {
            return (baslik: "Kritik Yan Hak Kaybı", metin: "Yeni şirkette hiçbir sağlık sigortası yan hakkı bulunmuyor. Özel hastane kullanma alışkanlığın varsa, bu durum sana yıl içinde on binlerce liralık sürpriz sağlık masrafları çıkarabilir. Dikkatli olmalısın.", ikon: "cross.fill", renk: appTheme.dangerColor)
        } else if mOzel && tOzel {
            return (baslik: "Özel Sağlık Sigortası Korunuyor", metin: "Her iki şirket de Özel Sağlık Sigortası (ÖSS) sunuyor. Kapsamlı sağlık güvencen ve A sınıfı hastane erişimin aynı şekilde devam edecek.", ikon: "checkmark.seal.fill", renk: appTheme.primaryAccent)
        } else if mTamam && tTamam {
            return (baslik: "Tamamlayıcı Sigorta Korunuyor", metin: "Her iki şirketin de sunduğu Tamamlayıcı Sağlık Sigortası (TSS) imkanıyla temel özel hastane güvenceni korumaya devam ediyorsun.", ikon: "checkmark.shield.fill", renk: appTheme.primaryAccent)
        }
        return (baslik: "Sigorta İmkânı Bulunmuyor", metin: "Her iki şirkette de özel bir sağlık sigortası desteği bulunmuyor. Olası özel sağlık harcamalarını kendi bütçenden planlaman gerekecek.", ikon: "exclamationmark.circle.fill", renk: appTheme.textSecondary)
    }

    // MARK: - Kariyer Stratejisi Algoritması
    private func kariyerYorumuUret(mevcutNet: Double, teklifNet: Double) -> (baslik: String, metin: String, ikon: String, renk: Color) {
        let model = viewModel.draft
        let artisOrani = mevcutNet > 0 ? ((teklifNet - mevcutNet) / mevcutNet) : 0.0
        
        if model.terfiVarMi {
            let mevcutRank = model.mevcutUnvanRank > 0 ? model.mevcutUnvanRank : 1
            let teklifRank = model.teklifUnvanRank > 0 ? model.teklifUnvanRank : 1
            let kademeFarki = teklifRank - mevcutRank
            if kademeFarki >= 2 {
                return (baslik: "Agresif Sıçrama (Fast-Track)", metin: "Harika bir sıçrama! Birden fazla kademe atlayarak gidiyorsun. Kariyerinde agresif ve çok güçlü bir ivme yakalıyorsun. Ancak unutma; yeni şirkette senden beklentiler ilk günden çok yüksek olacak. Dik bir öğrenme eğrisine ve yoğun bir tempoya zihnen hazır olmalısın.", ikon: "flame.fill", renk: appTheme.warningColor)
            } else {
                return (baslik: "İdeal Kariyer Adımı", metin: "Tebrikler! Kariyer merdiveninde sağlam ve doğru bir adım atıyorsun. Yeni bir unvanla farklı bir şirkete geçmek, CV'ne hem yeni yetkinlikler hem de artan sorumluluk seviyesi olarak yansıyacaktır. Bu unvan piyasa değerini kalıcı olarak yukarı taşıyacak.", ikon: "star.fill", renk: appTheme.successColor)
            }
        } else {
            let yil = model.mevcutUnvanYil
            let dusukZamMi = artisOrani < 0.20
            if yil >= 4 && dusukZamMi {
                let yuzdeMetni = String(format: "%.1f", artisOrani * 100)
                return (baslik: "⚠️ Stratejik Risk (Kariyer Tuzağı)", metin: "Mevcut unvanında \(yil) yılı geride bırakmışsın. Yeni şirkete aynı unvanla ve %20'den az bir finansal artışla (%\(yuzdeMetni)) geçiyorsun. Yeni şirkette terfi bekleme süren sıfırlanacaktır ve kendini kanıtlaman en az 1 yıl daha alacaktır. Stratejik olarak iki kez düşünmelisin.", ikon: "exclamationmark.triangle.fill", renk: appTheme.dangerColor)
            } else if yil >= 4 && !dusukZamMi {
                return (baslik: "Karlı Yatay Geçiş", metin: "Mevcut unvanında \(yil) yıl geçirmişsin. Yeni şirkete aynı unvanla gitsen de, aldığın güçlü finansal artış bu geçişi mantıklı kılıyor. Gittiğin yerde ilk hedefin hızlıca bir üst unvanı kovalamak olmalı.", ikon: "arrow.right.arrow.left.circle.fill", renk: appTheme.primaryAccent)
            } else {
                return (baslik: "Yatay Geçiş (Lateral Move)", metin: "Yeni şirketine aynı unvanla geçiş yapıyorsun. Bu tarz yatay geçişler, yeni bir sektör veya kurum kültürü tanımak için harika fırsatlardır. Terfi (promotion) saatini çok fazla geciktirmeden, gittiğin yerde yetkinliklerini hızla kanıtlamaya odaklan.", ikon: "arrow.right.circle.fill", renk: appTheme.primaryAccent)
            }
        }
    }
    
    // MARK: - Yemek & Esnek Bütçe Algoritması
    private func yemekYorumuUret() -> (baslik: String, metin: String, ikon: String, renk: Color) {
        let mevcutTipi = viewModel.draft.mevcutYemekTipi
        let teklifTipi = viewModel.draft.teklifYemekTipi
        let mevcutTutar = viewModel.draft.mevcutGunlukYemekUcreti * 22
        let teklifTutar = viewModel.draft.teklifGunlukYemekUcreti * 22
        let mevcutYildiz = viewModel.draft.mevcutYemekLezzetYildiz
        let teklifYildiz = viewModel.draft.teklifYemekLezzetYildiz
        
        if teklifTipi == "Yok" || teklifTipi.isEmpty {
            if mevcutTipi != "Yok" && !mevcutTipi.isEmpty {
                return (baslik: "Ciddi Bir Yan Hak Kaybı", metin: "Mevcut işindeki yemek imkânını kaybediyorsun. Türkiye şartlarında günde 1 öğün yemeği cebinden karşılamak aylık ortalama 6.000 - 8.000 TL arası 'gizli bir masraf' yaratır. Maaş zammını hesaplarken bu nakit kaybını mutlaka hesaba katmalısın.", ikon: "takeoutbag.and.cup.and.straw.fill", renk: appTheme.dangerColor)
            } else {
                return (baslik: "Gizli Masraf Devam Ediyor", metin: "Her iki şirkette de yemek desteği bulunmuyor. Aylık yemek masraflarını maaşından ve kendi cebinden karşılamaya devam edeceksin.", ikon: "exclamationmark.circle.fill", renk: appTheme.warningColor)
            }
        }
        if (mevcutTipi == "Yok" || mevcutTipi.isEmpty) && (teklifTipi != "Yok" && !teklifTipi.isEmpty) {
            let ekYorum = teklifTipi == "Yemek Kartı" ? "Aylık ortalama \(formatPara(teklifTutar)) değerinde esnek bir bütçe kazanıyorsun." : "Şirket içi yemekhane ile günlük yemek masrafından tamamen kurtuluyorsun."
            return (baslik: "Yeni Bir Yan Hak Kazanımı", metin: "Önceden kendi cebinden karşıladığın yemek masrafı artık yeni şirketin tarafından karşılanacak. \(ekYorum) Bu, net maaşına eklenmiş vergisiz bir nakit kazanç gibidir.", ikon: "gift.fill", renk: appTheme.successColor)
        }
        if mevcutTipi == "Yemek Kartı" && teklifTipi == "Yemek Kartı" {
            let fark = teklifTutar - mevcutTutar
            if fark > 0 { return (baslik: "Yemek Bütçesinde Artış", metin: "Aylık yemek kartı bütçen \(formatPara(mevcutTutar)) seviyesinden \(formatPara(teklifTutar)) seviyesine çıkıyor. Ekstra \(formatPara(fark)) değerindeki bu artışı market alışverişlerinde esnek bütçe olarak kullanabilirsin.", ikon: "arrow.up.right.circle.fill", renk: appTheme.successColor) }
            else if fark < 0 { return (baslik: "Yemek Bütçesinde Düşüş", metin: "Yeni şirkette aylık yemek kartı bütçen \(formatPara(abs(fark))) kadar azalacak. Toplam finansal kazancını hesaplarken bu vergisiz nakit kaybını da göz önünde bulundurmalısın.", ikon: "arrow.down.right.circle.fill", renk: appTheme.warningColor) }
            else { return (baslik: "Aynı Yemek Bütçesi", metin: "Her iki şirketin de aylık yemek kartı tutarı birbiriyle aynı seviyede. Ev bütçene olan katkısında bir değişiklik olmayacak.", ikon: "equal.circle.fill", renk: appTheme.primaryAccent) }
        }
        if mevcutTipi == "Yemekhane" && teklifTipi == "Yemekhane" {
            if teklifYildiz > mevcutYildiz { return (baslik: "Daha Kaliteli Yemekler", metin: "Yeni şirketin yemekhane puanı (\(teklifYildiz) Yıldız) mevcut şirketinden daha iyi görünüyor. Öğle yemeklerinde hem masrafsız hem de çok daha lezzetli bir deneyim yaşayacaksın.", ikon: "star.fill", renk: appTheme.successColor) }
            else if teklifYildiz < mevcutYildiz { return (baslik: "Lezzet Kalitesinde Düşüş", metin: "Yeni şirketinde yemekhane var ancak lezzet beklentisi (Sadece \(teklifYildiz) Yıldız) mevcut işindeki kadar iyi değil. Bu durum seni ara sıra dışarıdan yemek sipariş etmeye itebilir.", ikon: "exclamationmark.triangle.fill", renk: appTheme.warningColor) }
            else { return (baslik: "Benzer Yemekhane Deneyimi", metin: "Her iki şirketin de yemekhane kalitesi benzer seviyede (\(teklifYildiz) Yıldız). Öğle yemeği konforunda bir değişiklik yaşamayacaksın.", ikon: "fork.knife", renk: appTheme.primaryAccent) }
        }
        if mevcutTipi == "Yemekhane" && teklifTipi == "Yemek Kartı" {
            return (baslik: "Konfordan Esnek Bütçeye Geçiş", metin: "Hazır yemekhane konforunu bırakıp aylık ortalama \(formatPara(teklifTutar)) değerinde bir yemek kartına geçiyorsun. Bu kartı market alışverişlerinde de kullanarak doğrudan ev bütçene destek sağlayabilirsin.", ikon: "creditcard.fill", renk: appTheme.primaryAccent)
        }
        if mevcutTipi == "Yemek Kartı" && teklifTipi == "Yemekhane" {
            let kaliteYorumu = teklifYildiz >= 4 ? "Üstelik \(teklifYildiz) yıldızlı bu yemekhane, dışarıdan yeme isteğini tamamen sıfırlayacaktır." : "Ancak \(teklifYildiz) yıldızlı düşük bir lezzet beklentisi olduğu için bazen dışarıdan sipariş verme ihtiyacı duyabilirsin."
            return (baslik: "Esnek Bütçeden Hazır Konfora", metin: "Mevcut işindeki \(formatPara(mevcutTutar)) değerindeki market/yemek bütçeni bırakıp şirket içi yemekhaneye geçiyorsun. Karar verme stresin ve yemek arama derdin bitiyor. \(kaliteYorumu)", ikon: "tray.full.fill", renk: appTheme.primaryAccent)
        }
        return (baslik: "Yemek İmkânı Analizi", metin: "İki şirketin sunduğu yemek yan hakları birbirinden farklı. İhtiyaçlarına göre tercih yapmalısın.", ikon: "bag.fill", renk: appTheme.textPrimary)
    }
    
    // MARK: - Çalışma Modeli Puanlama
    private func calismaModeliYorumu() -> String {
        let mevcutPuan = puanla(model: viewModel.draft.mevcutCalismaModeli, gun: viewModel.draft.mevcutOfisGunSayisi)
        let teklifPuan = puanla(model: viewModel.draft.teklifCalismaModeli, gun: viewModel.draft.teklifOfisGunSayisi)
        if teklifPuan > mevcutPuan { return "Çalışma modeli olarak harika bir yükseliş! Daha esnek ve özgür bir düzene geçiyorsun. Evden çalışma oranının artması sana ciddi bir zaman ve yaşam kalitesi kazandıracak." }
        else if teklifPuan < mevcutPuan { return "Maddi tarafı bir yana, yeni teklifte çalışma esnekliğini kaybediyorsun. Ofise daha fazla gitmek demek; yolda geçen zamanın, yorgunluğun ve yol masraflarının artması demektir." }
        else { return "Her iki şirketin de çalışma modeli ve ofise gitme sıklığı birbiriyle aynı seviyede." }
    }
    
    private func puanla(model: String, gun: Int) -> Int {
        let text = model.lowercased()
        if text.contains("uzaktan") || text.contains("remote") { return 100 }
        if text.contains("hibrit") || text.contains("hybrid") { return max(0, 50 - (gun * 10)) }
        return 0
    }
    
    // MARK: - Formatlayıcılar
    private func formatPara(_ miktar: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₺"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: miktar)) ?? "₺0"
    }
    
    private func formatYuzde(_ miktar: Double) -> String {
        return String(format: "%.1f", miktar).replacingOccurrences(of: ".", with: ",")
    }
}

// MARK: - Alt Bileşenler

struct AylikKutu: View {
    let sirket: String
    let ortalama: Double
    let renk: Color
    
    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: ortalama)) ?? "0"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(sirket).font(.caption.bold()).foregroundColor(renk).lineLimit(1)
            Text("₺\(formattedAmount)").font(.title3.bold())
            Text("Aylık Net Maaş").font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(renk.opacity(0.05))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(renk.opacity(0.15), lineWidth: 1))
    }
}

struct ModelKutusu: View {
    let baslik: String
    let model: String
    let gun: Int
    let renk: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(baslik).font(.caption.bold()).foregroundColor(renk).lineLimit(1)
            Text(model.isEmpty ? "Belirtilmedi" : model).font(.subheadline.bold())
            if model.lowercased().contains("hibrit") {
                Text("\(gun) Gün Ofis").font(.caption2).foregroundColor(.secondary)
            } else {
                Text(model.lowercased().contains("uzaktan") ? "0 Gün Ofis" : "Tam Zamanlı Ofis").font(.caption2).foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct PremiumBar: View {
    let baslik: String
    let deger: Double
    let maxDeger: Double
    let renk: Color
    let animasyonBasladi: Bool
    
    private var formattedValue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₺"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: deger)) ?? "₺0"
    }
    
    var body: some View {
        let oran = maxDeger > 0 ? CGFloat(deger / maxDeger) : 0
        VStack(spacing: 10) {
            HStack(alignment: .bottom) {
                Text(baslik).font(.subheadline.bold()).foregroundColor(.secondary)
                Spacer()
                Text(formattedValue).font(.title3.weight(.heavy)).foregroundColor(renk)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(renk.opacity(0.1)).frame(height: 18)
                    Capsule()
                        .fill(LinearGradient(colors: [renk.opacity(0.5), renk], startPoint: .leading, endPoint: .trailing))
                        .frame(width: animasyonBasladi ? max(geo.size.width * oran, 24) : 0, height: 18)
                        .shadow(color: renk.opacity(0.4), radius: 6, x: 0, y: 3)
                }
            }
            .frame(height: 18)
        }
    }
}

struct KiyasSatiri: View {
    let baslik: String
    let m1: String
    let m2: String
    
    var body: some View {
        VStack(spacing: 6) {
            HStack { Text(baslik).font(.caption).foregroundColor(.secondary); Spacer() }
            HStack {
                Text(m1.isEmpty ? "-" : m1).font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "arrow.right").font(.caption2).foregroundColor(.gray)
                Text(m2.isEmpty ? "-" : m2).font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity, alignment: .trailing)
            }
            Divider().padding(.top, 4)
        }
    }
}

struct JustifiedText: View {
    let text: String
    
    init(_ text: String) { self.text = text }
    
    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
