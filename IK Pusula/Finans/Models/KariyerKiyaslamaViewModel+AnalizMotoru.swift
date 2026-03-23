// ================================================================
// KariyerKiyaslamaViewModel+AnalizMotoru
// Ulaşım, sağlık, yıllık izin ve kıdem tazminatı analiz motorları.
// ================================================================

import Foundation

private func fp(_ v: Double) -> String {
    let f = NumberFormatter()
    f.numberStyle = .currency
    f.currencySymbol = "₺"
    f.maximumFractionDigits = 0
    f.locale = Locale(identifier: "tr_TR")
    return f.string(from: NSNumber(value: v)) ?? "₺0"
}

extension KariyerKiyaslamaViewModel {

    // MARK: — 1. ULAŞIM VE KONFOR ANALİZ MOTORU
    func ulasimAnaliziUret() -> String {
        let m = draft

        func ulasimTipi(calisma: String, aracSeg: String, kalite: String) -> String {
            if calisma.localizedCaseInsensitiveContains("uzaktan") { return "Uzaktan" }
            let seg = aracSeg.trimmingCharacters(in: .whitespaces)
            if !seg.isEmpty && seg.lowercased() != "yok" { return "ŞirketAracı" }
            if kalite.localizedCaseInsensitiveContains("servis") { return "Servis" }
            if kalite.localizedCaseInsensitiveContains("toplu") { return "TopluUlasim" }
            if kalite.localizedCaseInsensitiveContains("kendi") { return "SahsiArac" }
            return "TopluUlasim"
        }

        let mTip = ulasimTipi(calisma: m.mevcutCalismaModeli, aracSeg: m.mevcutAracSegment, kalite: m.mevcutUlasimKalitesi)
        let tTip = ulasimTipi(calisma: m.teklifCalismaModeli, aracSeg: m.teklifAracSegment, kalite: m.teklifUlasimKalitesi)
        let mSeg = m.mevcutAracSegment
        let tSeg = m.teklifAracSegment
        let mRank = segmentRank(mSeg)
        let tRank = segmentRank(tSeg)
        let mYakitTipi = m.mevcutYakitDestekTipi
        let tYakitTipi = m.teklifYakitDestekTipi

        let mSure = m.mevcutYolSureDakika
        let tSure = m.teklifYolSureDakika
        let sureFark = tSure - mSure
        let aylikSaatFark = abs(sureFark * 22) / 60

        func sureYorumu() -> String {
            guard mSure > 0 || tSure > 0 else { return "" }
            if sureFark < -5 {
                return " Üstelik yolda günde **\(abs(sureFark)) dakika** tasarruf edeceksin — ayda **\(aylikSaatFark) saate** karşılık geliyor."
            } else if sureFark > 5 {
                return " Öte yandan yola günde **\(sureFark) dakika** daha harcayacaksın (aylık **\(aylikSaatFark) saat** ekstra)."
            }
            return ""
        }

        if mTip == "Uzaktan" && tTip == "Uzaktan" {
            return "İki şirkette de uzaktan çalışmaya devam ediyorsun. Ulaşım maliyeti, yolda geçen süre ve trafik stresi hayatından çıkmaya devam ediyor. Kararını verirken ulaşım konusu bir değişken değil — diğer faktörlere odaklanabilirsin."
        }

        if mTip != "Uzaktan" && tTip == "Uzaktan" {
            let yillikKazanilanSaat = (mSure * 22 * 12) / 60
            let mevcutUlasimMaliyeti: Double
            if mTip == "ŞirketAracı" {
                mevcutUlasimMaliyeti = CarPriceService.shared.monthlyPrice(for: mSeg) * 12
            } else if mTip == "SahsiArac" {
                mevcutUlasimMaliyeti = (parseFormattedNumber(m.mevcutKendiAracAylikGider) ?? 0) * 12
            } else {
                mevcutUlasimMaliyeti = (parseFormattedNumber(m.mevcutTopluTasimaTutar) ?? 0) * 12
            }

            var metin = "Tamamen uzaktan çalışmaya geçmek, bu kıyaslamada finansal rakamların ötesinde gerçek bir hayat kalitesi dönüşümü. "
            if mSure > 0 {
                metin += "Yılda yaklaşık **\(yillikKazanilanSaat) saat** — düşün bir an, bu neredeyse **\(yillikKazanilanSaat / 8) iş günü** — tamamen sana kalacak. "
            }
            if mevcutUlasimMaliyeti > 0 && mTip != "ŞirketAracı" {
                metin += "Ulaşım masrafı olarak cebinden çıkan **\(fp(mevcutUlasimMaliyeti / 12))/ay** tutarını artık başka bir şeye harcayabilirsin. "
            }
            metin += "Sabah rutini, öğle arası, akşam yorgunluğu — bunların tamamı köklü biçimde değişecek. Bu dönüşümün uzun vadeli değeri, maaş farkının çok ötesinde olabilir."
            return metin
        }

        if mTip == "Uzaktan" && tTip != "Uzaktan" {
            let yillikKaybedilenSaat = (tSure * 22 * 12) / 60
            var metin = "Evden çalışmanın sağladığı o eşsiz özgürlük alanından çıkıp, fiziksel işyerine dönüyorsun. "
            if tSure > 0 {
                metin += "Yılda yaklaşık **\(yillikKaybedilenSaat) saat**ini yollarda geçireceksin — bu ciddi bir zaman yatırımı. "
            }
            if tTip == "ŞirketAracı" {
                let aylikKira = CarPriceService.shared.monthlyPrice(for: tSeg)
                metin += "Ama yeni şirketin **\(tSeg)** araç tahsis ediyor"
                if aylikKira > 0 { metin += " (aylık piyasa değeri yaklaşık **\(fp(aylikKira))**)" }
                metin += "; bu, ulaşım masrafını sıfırlıyor ve kısmen telafi sağlıyor. "
            } else if tTip == "Servis" {
                metin += "Neyse ki yeni işe şirket servisiyle gideceksin — sürüş stresi ve park derdin olmayacak. "
            }
            metin += "Aldığın maaş artışının, bu kaybettiğin zaman ve esnekliğin gerçek bedelini karşılayıp karşılamadığını iyi hesapla."
            return metin
        }

        if mTip == "ŞirketAracı" && tTip == "ŞirketAracı" {
            let mKira = CarPriceService.shared.monthlyPrice(for: mSeg)
            let tKira = CarPriceService.shared.monthlyPrice(for: tSeg)
            let segFark = tKira - mKira

            if mRank == tRank {
                let mYakitStr = yakitDurumMetni(tip: mYakitTipi, isCurrent: true)
                let tYakitStr = yakitDurumMetni(tip: tYakitTipi, isCurrent: false)
                var metin = "Şirket aracı ayrıcalığın devam ediyor ve segment aynı (**\(mSeg.isEmpty ? "—" : mSeg)**). "
                if mYakitStr != tYakitStr {
                    metin += "Tek fark yakıt tarafında: Mevcut işinde \(mYakitStr), yeni işinde ise \(tYakitStr). "
                    if tYakitTipi.localizedCaseInsensitiveContains("limitsiz") {
                        metin += "Limitsiz yakıt, yıllık binlerce lira ek tasarruf anlamına geliyor — bu küçük ama önemli bir kazanım."
                    } else if mYakitTipi.localizedCaseInsensitiveContains("limitsiz") {
                        metin += "Limitsiz yakıt avantajını kaybediyorsun; bu yıllık cebinden çıkacak ek bir masraf kalemi demek."
                    }
                } else {
                    metin += "Araç standardın ve yakıt koşulların olduğu gibi korunuyor.\(sureYorumu())"
                }
                return metin
            }

            if tRank > mRank {
                let yillikFark = segFark * 12
                var metin = "Araç ayrıcalığın devam ediyor ve segment yükseliyor: **\(mSeg)** → **\(tSeg)**. "
                metin += "Bu yükseltme, aylık yaklaşık **\(fp(tKira - mKira))** değerinde bir piyasa farkına karşılık geliyor (yılda **\(fp(yillikFark))**). "
                if tYakitTipi.localizedCaseInsensitiveContains("limitsiz") && !mYakitTipi.localizedCaseInsensitiveContains("limitsiz") {
                    metin += "Üstelik yeni işte yakıtın da şirket tarafından limitsiz karşılanacak — bu kombinasyon gerçekten güçlü bir yan hak paketi. "
                } else if tYakitTipi.localizedCaseInsensitiveContains("limitsiz") {
                    metin += "Limitsiz yakıt desteği de aynen devam ediyor. "
                }
                metin += "Daha üst segment sürüş konforu, motivasyona ve şirket içi prestije de olumlu yansıyacaktır.\(sureYorumu())"
                return metin
            }

            let yillikFark = abs(segFark) * 12
            var metin = "Şirket aracı konforun devam ediyor ama segment düşüyor: **\(mSeg)** → **\(tSeg)**. "
            metin += "Bu fark, aylık yaklaşık **\(fp(abs(segFark)))** değerinde (yılda **\(fp(yillikFark))**). "
            if tYakitTipi.localizedCaseInsensitiveContains("limitsiz") && !mYakitTipi.localizedCaseInsensitiveContains("limitsiz") {
                metin += "Ama yeni işte yakıtın limitsiz karşılanması bu segment kaybını büyük ölçüde dengeleyen bir unsur. "
            } else if !tYakitTipi.localizedCaseInsensitiveContains("limitsiz") && mYakitTipi.localizedCaseInsensitiveContains("limitsiz") {
                metin += "Hem segment hem yakıt koşulları gerilediği için bu yan hak paketinde kayıp var — maaş tarafının bunu ne ölçüde karşıladığını değerlendirmelisin. "
            }
            metin += "Aracın hâlâ şirket tarafından karşılanıyor olması finansal güvenceni koruyor.\(sureYorumu())"
            return metin
        }

        if mTip != "ŞirketAracı" && tTip == "ŞirketAracı" {
            let aylikKira = CarPriceService.shared.monthlyPrice(for: tSeg)
            let yillikKira = aylikKira * 12
            var metin = ""

            if mTip == "SahsiArac" {
                let mevcutGider = (parseFormattedNumber(m.mevcutKendiAracAylikGider) ?? 0)
                let yillikTasarruf = (mevcutGider + aylikKira) * 12
                metin = "Kendi aracınla harcadığın **\(fp(mevcutGider))/ay** yakıt/bakım giderinin yanı sıra, artık **\(tSeg)** segment şirket aracına biniyorsun. "
                metin += "Bu geçiş; kasko, sigorta, bakım, muayene masraflarından kurtulmak ve aylık **\(fp(mevcutGider + aylikKira))** tasarruf (yıllık **\(fp(yillikTasarruf))**) anlamına geliyor. "
            } else if mTip == "TopluUlasim" {
                let mevcutGider = (parseFormattedNumber(m.mevcutTopluTasimaTutar) ?? 0)
                metin = "Toplu taşımadan **\(tSeg)** segment şirket aracına geçiş, hem konfor hem de bütçe açısından ciddi bir sıçrama. "
                if mevcutGider > 0 { metin += "Aylık **\(fp(mevcutGider))** ulaşım masrafın sıfırlanıyor. " }
            } else if mTip == "Servis" {
                metin = "Şirket servisinin kalabalığından çıkıp kendi **\(tSeg)** araçla işe gideceksin. "
                metin += "Seyahat saatini tamamen kendin belirleyebileceksin; bu esneklik çok değerli. "
            } else {
                metin = "Şirket aracı tahsisi gerçek bir yaşam standardı yükselişi. "
            }

            if aylikKira > 0 {
                metin += "Piyasada **\(tSeg)** segment aracın aylık kiralama bedeli yaklaşık **\(fp(aylikKira))** (yıllık **\(fp(yillikKira))**). "
            }

            if tYakitTipi.localizedCaseInsensitiveContains("limitsiz") {
                metin += "Üstelik yakıtın da limitsiz şirket tarafından karşılanıyor — bu gerçekten eksiksiz bir araç paketi."
            } else if tYakitTipi.localizedCaseInsensitiveContains("limitli") {
                let yakitTutar = parseFormattedNumber(m.teklifYakitDestekTutar) ?? 0
                metin += "Yakıt da \(yakitTutar > 0 ? "aylık **\(fp(yakitTutar))** limitli" : "kısmen") şirket tarafından karşılanıyor."
            } else {
                metin += "Yakıt masrafı ise sana ait — bunu bütçene dahil etmeyi unutma."
            }
            return metin + sureYorumu()
        }

        if mTip == "ŞirketAracı" && tTip != "ŞirketAracı" {
            let aylikKira = CarPriceService.shared.monthlyPrice(for: mSeg)
            let yillikKira = aylikKira * 12
            var metin = "**\(mSeg)** segment şirket aracını bırakıyorsun. "
            if aylikKira > 0 {
                metin += "Bu aracın piyasa kiralama değeri aylık **\(fp(aylikKira))** (yıllık **\(fp(yillikKira))**) — bu tutarı artık kendi cebinden karşılaman ya da kendi aracını kullanman gerekecek. "
            }
            if tTip == "Servis" {
                metin += "Yeni işe servisle gidecek olman ulaşım masrafını sıfırlıyor, bu önemli bir telafi. "
            } else if tTip == "TopluUlasim" {
                let topluTutar = parseFormattedNumber(m.teklifTopluTasimaTutar) ?? 0
                if topluTutar > 0 && m.teklifTopluTasimaDestekVarMi {
                    metin += "Neyse ki şirket toplu taşıma desteği (**\(fp(topluTutar))/ay**) sağlıyor; bu kayıpla bir miktar baş ediyor. "
                } else if topluTutar > 0 {
                    metin += "Aylık **\(fp(topluTutar))** ulaşım gideri de bu kez cebinden çıkacak. "
                }
            }
            metin += "Kasko, bakım ve muayene sorumluluğu da sana geçeceği için maaş artışının bu maliyeti gerçekten karşılayıp karşılamadığını net hesapla."
            return metin + sureYorumu()
        }

        if mTip == "TopluUlasim" && tTip == "Servis" {
            let mevcutGider = parseFormattedNumber(m.mevcutTopluTasimaTutar) ?? 0
            var metin = "Kalabalık ve stresli toplu taşımadan şirket servisine geçiş, ulaşım kaliteni ciddi ölçüde artırıyor. "
            if mevcutGider > 0 && !m.mevcutTopluTasimaDestekVarMi {
                metin += "Aylık **\(fp(mevcutGider))** ulaşım masrafın ortadan kalkıyor. "
            }
            metin += "Sabahları garantili bir koltuk, akşamları kapıdan kapıya servis konforu — bu, enerji ve odak üzerinde gerçek bir fark yaratır."
            return metin + sureYorumu()
        }

        if mTip == "Servis" && tTip == "TopluUlasim" {
            let teklifGider = parseFormattedNumber(m.teklifTopluTasimaTutar) ?? 0
            var metin = "Şirket servisinin konforundan toplu taşımaya geçiyorsun. "
            if teklifGider > 0 {
                if m.teklifTopluTasimaDestekVarMi {
                    metin += "Neyse ki yeni şirket **\(fp(teklifGider))/ay** toplu taşıma desteği veriyor. "
                } else {
                    metin += "Aylık **\(fp(teklifGider))** ulaşım masrafı artık cebinden çıkacak. "
                }
            }
            metin += "Kalabalık ve beklenmedik gecikmeler, seyahat kaliteni düşürecek; bunu tolere edip edemeyeceğini düşünmelisin."
            return metin + sureYorumu()
        }

        if mTip == "SahsiArac" && tTip == "SahsiArac" {
            let mGider = parseFormattedNumber(m.mevcutKendiAracAylikGider) ?? 0
            let tGider = parseFormattedNumber(m.teklifKendiAracAylikGider) ?? 0
            let mKimin = m.mevcutKendiAracGiderKimin
            let tKimin = m.teklifKendiAracGiderKimin

            if mKimin != tKimin {
                if tKimin.localizedCaseInsensitiveContains("şirket") || tKimin.localizedCaseInsensitiveContains("sirket") {
                    return "Her iki işte de kendi araçla gideceksin; ama önemli fark şu: Yeni işinde yakıt ve araç giderlerin şirket tarafından karşılanacak. Bu, aylık **\(fp(mGider))** tasarruf anlamına geliyor." + sureYorumu()
                } else {
                    return "Her iki işte de kendi araçla gidiyorsun ama yeni işinde yakıt/bakım giderleri artık kendi cebinden. Aylık **\(fp(tGider))** ek maliyet göz önünde bulundurulmalı." + sureYorumu()
                }
            }
            if abs(mGider - tGider) > 500 {
                let fark = tGider - mGider
                return "Her iki işte de kendi araçla gidiyorsun. Aylık araç giderin \(fark > 0 ? "**\(fp(fark)) artıyor**" : "**\(fp(abs(fark))) azalıyor**") — yıllık **\(fp(abs(fark) * 12))** fark." + sureYorumu()
            }
            return "Her iki işte de kendi araçla gideceksin, büyük bir fark yok." + sureYorumu()
        }

        let mGider = parseFormattedNumber(m.mevcutTopluTasimaTutar) ?? 0
        let tGider = parseFormattedNumber(m.teklifTopluTasimaTutar) ?? 0
        let fark = tGider - mGider
        if mTip == tTip && abs(fark) < 200 {
            return "Ulaşım şeklinde ve maliyetinde kayda değer bir değişiklik olmuyor." + sureYorumu()
        }
        if mTip == tTip && fark > 200 {
            return "Aynı ulaşım yöntemini kullanmaya devam ediyorsun ama aylık giderin **\(fp(fark))** artıyor." + sureYorumu()
        }
        return "Ulaşım koşullarında kayda değer bir değişiklik olmuyor." + sureYorumu()
    }

    private func yakitDurumMetni(tip: String, isCurrent: Bool) -> String {
        if tip.localizedCaseInsensitiveContains("limitsiz") { return "limitsiz yakıt" }
        if tip.localizedCaseInsensitiveContains("limitli") {
            let tutar = parseFormattedNumber(isCurrent ? draft.mevcutYakitDestekTutar : draft.teklifYakitDestekTutar) ?? 0
            return "limitli yakıt (\(tutar > 0 ? fp(tutar) + "/ay" : "belirsiz limit"))"
        }
        return "yakıt kendin karşılıyor"
    }

    // MARK: — 2. SAĞLIK VE GÜVENCE ANALİZ MOTORU
    func saglikAnaliziUret() -> String {
        let m = draft
        let mTip = m.mevcutSigortaTipi
        let tTip = m.teklifSigortaTipi
        let mKisi = max(1, m.mevcutSigortaYararlananKisiSayisi)
        let tKisi = max(1, m.teklifSigortaYararlananKisiSayisi)
        let mAile = mKisi > 1
        let tAile = tKisi > 1

        func rank(_ s: String) -> Int {
            let t = s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if t.contains("özel") || t == "öss" { return 3 }
            if t.contains("tamamlayıcı") || t == "tss" { return 2 }
            return 1
        }

        let mR = rank(mTip)
        let tR = rank(tTip)

        let mNet = calculateNet(isCurrent: true, includePrim: true).yillikNet
        let tNet = calculateNet(isCurrent: false, includePrim: true).yillikNet
        let maasArtisi = tNet - mNet

        let ossFiyat = HealthInsurancePriceService.shared.yearlyPrice(for: "Özel")
        let tssFiyat = HealthInsurancePriceService.shared.yearlyPrice(for: "Tamamlayıcı")

        func ossYillikDeger(_ kisi: Int) -> Double { ossFiyat * Double(kisi) }
        func tssYillikDeger(_ kisi: Int) -> Double { tssFiyat * Double(kisi) }

        if mR == tR {
            if mR == 3 {
                if !mAile && tAile {
                    let ekDeger = ossYillikDeger(tKisi) - ossYillikDeger(1)
                    return "Her iki işte de **Özel Sağlık Sigortası (ÖSS)** var ve A sınıfı hastane ayrıcalığın devam ediyor. Önemli fark: Yeni işte sigortan **\(tKisi) kişilik aile kapsamına** genişliyor. Bu, yıllık yaklaşık **\(fp(ekDeger))** değerinde ek güvence demek — aileniz için paha biçilmez bir kazanım."
                }
                if mAile && !tAile {
                    let kaybDeger = ossYillikDeger(mKisi) - ossYillikDeger(1)
                    return "ÖSS ayrıcalığın devam ediyor ama yeni işte **aile kapsamını kaybediyorsun**. Mevcut işindeki \(mKisi) kişilik aile sigortanın yıllık değeri yaklaşık **\(fp(kaybDeger))**. Bunu bireysel poliçeyle karşılamak ciddi bir ek maliyet getirir — maaş artışın bu farkı kapatıyor mu iyi hesapla."
                }
                if mAile && tAile && mKisi != tKisi {
                    let fark = tKisi - mKisi
                    return "Her iki işte de aile kapsamlı **ÖSS** var. Yeni işte yararlanan kişi sayısı \(fark > 0 ? "\(abs(fark)) kişi artıyor (**\(tKisi) kişi**)" : "\(abs(fark)) kişi azalıyor (**\(tKisi) kişi**)"). Bu değişim yıllık yaklaşık **\(fp(abs(ossYillikDeger(tKisi) - ossYillikDeger(mKisi))))** etki yaratıyor."
                }
                return "Her iki şirkette de **Özel Sağlık Sigortası (ÖSS)** ayrıcalığın \(tAile ? "aile kapsamıyla" : "") devam ediyor. A sınıfı hastanelerde kapsamlı sağlık güvencen kesintisiz seninle. Kararında sağlık tarafı seni rahatlatabilir."
            }

            if mR == 2 {
                if !mAile && tAile {
                    return "Her iki işte de **Tamamlayıcı Sağlık Sigortası (TSS)** var. Yeni işte sigortan **\(tKisi) kişilik aile kapsamına** genişliyor — bu, ailenin sağlık masraflarını da güvence altına almak anlamına geliyor. Kayda değer bir kazanım."
                }
                if mAile && !tAile {
                    return "TSS imkânın devam ediyor ama yeni işte **aile kapsamını kaybediyorsun**. Aile bireylerinin özel hastane masrafları artık cebinden çıkacak. Bu önemli bir fark — gözardı etme."
                }
                return "Her iki işte de **Tamamlayıcı Sağlık Sigortası (TSS)** var. Anlaşmalı özel hastanelerde fark ücretsiz veya düşük maliyetli tedavi konforu aynen sürüyor.\(tAile ? " Aile kapsamı da korunuyor." : "")"
            }

            return "Her iki işte de özel bir sağlık sigortası yan hakkı bulunmuyor. Sağlık harcamalarını kendi bütçenden planlamaya devam edeceksin."
        }

        if mR == 2 && tR == 3 {
            let yillikFark = ossYillikDeger(tKisi) - tssYillikDeger(mKisi)
            var metin = "**TSS → ÖSS**: Tamamlayıcı sigortadan tam Özel Sağlık Sigortasına geçiş yapıyorsun. "
            metin += "A sınıfı premium hastaneler, daha geniş anlaşmalı ağ ve çok daha yüksek teminat limitleri artık seninle. "
            if tAile && !mAile {
                metin += "Üstelik aile kapsamı da eklendi — bu, gerçekten güçlü bir yan hak paketi. "
            } else if tAile {
                metin += "Aile kapsamı da korunuyor. "
            }
            if yillikFark > 0 {
                metin += "Bu yükseltmenin yıllık piyasa değeri yaklaşık **\(fp(yillikFark))** — seni sigorta şirketiyle pazarlık yapmak zorunda bırakmıyor."
            }
            return metin
        }

        if mR == 3 && tR == 2 {
            let kaybDeger = ossYillikDeger(mKisi) - tssYillikDeger(tKisi)
            var metin = "**ÖSS → TSS**: Özel Sağlık Sigortanı bırakıp Tamamlayıcı Sağlık Sigortasına geçiyorsun. "
            metin += "Anlaşmalı özel hastaneleri kullanmaya devam edebileceksin, ama A sınıfı hastaneler ve daha geniş teminat limitleri elinden gidecek. "

            if mAile && !tAile {
                metin += "Bir de bunun üstüne aile kapsamını kaybediyorsun — bu çok önemli bir çift kayıp. "
                if ossFiyat > 0 {
                    metin += "Bu iki kaybın toplam yıllık piyasa değeri **\(fp(kaybDeger))**. "
                }
                if maasArtisi > kaybDeger {
                    metin += "Maaş artışın bu kaybı geçiyor ama ailenin sağlık güvencesini değerlendirirken sadece rakama bakma."
                }
                return metin
            }

            if ossFiyat > 0 {
                metin += "Bu değişimin yıllık piyasa farkı yaklaşık **\(fp(kaybDeger))**. "
                if maasArtisi >= ossFiyat * 4 {
                    metin += "Aldığın güçlü maaş artışı bu poliçe kaybını **dört katından fazla** telafi ediyor; büyük resimden bakınca bu geçiş hâlâ finansal olarak çok avantajlı."
                } else if maasArtisi >= ossFiyat * 2 {
                    metin += "Aldığın maaş artışı bu değer kaybının yaklaşık **iki katı** — finansal denkleme bakınca kayıp tolere edilebilir düzeyde."
                } else if maasArtisi >= kaybDeger {
                    metin += "Maaş artışın bu değer kaybını tam olarak kapatıyor ama aşmıyor. Sağlık güvencesi tarafındaki fedakârlığın bilinçli yapıldığından emin ol."
                } else {
                    metin += "Maaş artışın bu sigorta kaybını tam telafi etmiyor. Bireysel bir ÖSS poliçesi yaptırmayı ciddi düşünmelisin."
                }
            }

            if !mAile && tAile {
                metin += " Pozitif taraf: Yeni işte aile kapsamı ekleniyor — bu, sigorta kalitesindeki gerilemeyi kısmen dengeleyen değerli bir unsur."
            }
            return metin
        }

        if mR == 1 && tR > 1 {
            let tip = tR == 3 ? "Özel Sağlık Sigortası (ÖSS)" : "Tamamlayıcı Sağlık Sigortası (TSS)"
            let yillikDeger = tR == 3 ? ossYillikDeger(tKisi) : tssYillikDeger(tKisi)
            var metin = "Mevcut işinde hiç olmayan **\(tip)** ayrıcalığına kavuşuyorsun. "
            if yillikDeger > 0 {
                metin += "Bu poliçenin yıllık piyasa değeri **\(fp(yillikDeger))\(tAile ? " (\(tKisi) kişi için)" : "")** — maaşına zam gibi görünmeyen ama cebinde gerçekten hissedilen bir kazanım. "
            }
            if tAile {
                metin += "Ailenin de kapsama dahil olması bu yan hakkın değerini kat be kat artırıyor. "
            }
            metin += tR == 3
                ? "Artık A sınıfı özel hastanelerde randevu alabilecek, kapsamlı yatarak/ayakta tedaviden yararlanabileceksin."
                : "Anlaşmalı özel hastanelerde fark ücretsiz tedavi konforu hayatına girecek."
            return metin
        }

        if mR > 1 && tR == 1 {
            let kaybDeger = mR == 3 ? ossYillikDeger(mKisi) : tssYillikDeger(mKisi)
            var metin = "Yeni işinde **hiçbir özel sağlık sigortası yan hakkı** bulunmuyor — bu kritik bir eksi. "
            if mAile {
                metin += "Hem kendi hem ailen için kaybettiğin bu güvencenin yıllık piyasa değeri **\(fp(kaybDeger))**. "
            } else if kaybDeger > 0 {
                metin += "Bu yan hakkın yıllık piyasa değeri yaklaşık **\(fp(kaybDeger))**. "
            }
            metin += "Aldığın maaş artışından bu tutarı çıkardığında gerçek gelir artışın ne oluyor? "
            if maasArtisi > 0 && maasArtisi < kaybDeger {
                metin += "Net hesaplamada, sigorta kaybını hesaba katınca aslında maaşın **azalmış** bile sayılabilir. Bunu çok dikkatli değerlendirmelisin."
            } else {
                metin += "Bireysel bir poliçe alımını mutlaka bütçene dahil et."
            }
            return metin
        }

        return "Sağlık sigortası koşulları aynı kalıyor."
    }

    // MARK: — 3. YILLIK İZİN ANALİZ MOTORU
    func yillikIzinAnaliziUret() -> String {
        let mIzin = draft.mevcutYillikIzin
        let tIzin = draft.teklifYillikIzin
        let fark = tIzin - mIzin

        let aylikNet = calculateNet(isCurrent: false, includePrim: false).aylikOrtalama
        let gunlukNet = aylikNet / 22.0
        let izinDegerFark = abs(Double(fark)) * gunlukNet

        if fark == 0 {
            return "Her iki işte de yıllık izin **\(mIzin) gün** — eşit. Kararını verirken bu faktör dengeyi bozmayacak."
        }

        if fark > 0 {
            var metin = "Yıllık **\(fark) gün** daha fazla izin hakkı kazanıyorsun — bu küçümsenecek bir şey değil. "
            if fark >= 5 {
                metin += "**\(fark) günlük** bu fark, her yıl sana ekstra bir tatil hakkı veriyor. "
            }
            if gunlukNet > 0 {
                metin += "Nakit karşılığı açısından bakınca yıllık yaklaşık **\(fp(izinDegerFark))** değerinde bir zaman varlığı bu. "
            }
            metin += "Hem zihinsel dinlenme hem aile zamanı hem de kişisel projeler için bu süreyi değerlendirme esnekliğin artıyor."
            return metin
        }

        var metin = "Yıllık **\(abs(fark)) gün** izin kaybediyorsun. "
        if abs(fark) >= 5 {
            metin += "Bu ciddi bir fark — her yıl çalışmaya devam ettiğin ve tatil yapamadığın **\(abs(fark)) gün** demek. "
        }
        if gunlukNet > 0 && izinDegerFark > 0 {
            metin += "Bu günlerin nakit karşılığı yıllık yaklaşık **\(fp(izinDegerFark))**. "
        }

        let mNet = calculateNet(isCurrent: true, includePrim: true).yillikNet
        let tNetVal = calculateNet(isCurrent: false, includePrim: true).yillikNet
        let maasArtisi = tNetVal - mNet
        if maasArtisi > izinDegerFark {
            metin += "Aldığın maaş artışı bu izin kaybının maddi değerini karşılıyor, ama izin sadece para değil — yorulmuş bir beyin için o dinlenme günlerinin değerini kendin bilirsin."
        } else {
            metin += "Üstelik maaş artışın bu kaybın değerini tam karşılamıyor. İzni finansal ve insani bir değer olarak birlikte değerlendirmen gerekiyor."
        }
        return metin
    }

    // MARK: — 4. KIDEM TAZMİNATI VE AMORTİSMAN
    func kidemAmortismanAnaliziUret() -> String {
        let m = draft
        let yil = m.mevcutUnvanYil

        if yil < 1 {
            return "Mevcut şirketinde henüz 1 yılını doldurmadığın için içeride yanan bir kıdem tazminatı riskin bulunmuyor. Kariyer hamleni yaparken finansal açıdan tamamen özgür bir pozisyondasın."
        }

        let kidemRisk = calculateKidemTazminatiRiski()
        let mNetYillik = calculateNet(isCurrent: true, includePrim: true).yillikNet
        let tNetYillik = calculateNet(isCurrent: false, includePrim: true).yillikNet
        let aylikFark = (tNetYillik - mNetYillik) / 12.0
        let tazStr = fp(kidemRisk)

        if aylikFark <= 0 {
            return "Mevcut işinde geçirdiğin **\(yil) yıla** karşılık içeride yaklaşık **\(tazStr)** değerinde kıdem tazminatın var. Yeni şirketin maaş teklifi mevcut net maaşının üzerine çıkmadığından bu tazminatı finansal olarak amorti etme imkânın bulunmuyor. Kararında kariyer gelişimi, vizyon ve yan hak kalitesi gibi softer faktörler daha belirleyici olacak."
        }

        let amortismanAy = kidemRisk / aylikFark
        let amortismanYil = amortismanAy / 12.0
        let sureStr = amortismanAy >= 12 ? String(format: "%.1f yıl", amortismanYil) : String(format: "%.0f ay", amortismanAy)

        if amortismanAy <= 3 {
            return "İçerideki **\(yil) yıllık** birikime karşılık **\(tazStr)** tazminat bırakıyorsun. Ama aldığın zam o kadar güçlü ki bu tutarı yalnızca **\(String(format: "%.0f", amortismanAy)) ay**da geri kazanıyorsun. Finansal açıdan tartışmasız üst düzey bir geçiş."
        }
        if amortismanAy <= 6 {
            return "Bıraktığın **\(tazStr)** kıdemi sadece **\(sureStr)**de amorti ediyorsun. **\(yil) yıllık** birikimi bu kadar kısa sürede geri kazanmak, aldığın teklifin gerçekten güçlü olduğunu gösteriyor."
        }
        if amortismanYil < Double(yil) {
            return "**\(yil) yıllık** birikimden **\(tazStr)** tazminat masada kalıyor. Yeni işindeki maaş artışınla bu tutarı **\(sureStr)**de geri kazanıyorsun — bu süre çalışılan yıldan kısa olduğu için geçiş rakamsal olarak mantıklı."
        }
        if amortismanYil < Double(yil) * 1.5 {
            return "**\(yil) yılın** karşılığı **\(tazStr)** kıdem bırakıyorsun. Amortisman süresi **\(sureStr)** — çalışılan yılı biraz aşıyor ama makul. Gideceğin yerdeki kariyer fırsatı ve yan haklar bu süreyi değerli kılıyorsa hesap tutabilir."
        }
        return "**\(yil) yıllık** birikimini (**\(tazStr)**) yeni işindeki artışla amorti etmen **\(sureStr)** alacak. Bu uzun bir süre; salt finansal perspektiften bakınca tazminat kaybı ağır basıyor. Yeni şirketin kariyer çapı, unvan, network ve vizyon faktörleri bu yatırımı anlamlı kılacak güçte mi, onu iyi sorgula."
    }

    private func segmentRank(_ segment: String) -> Int {
        let sira = ["A", "B", "C", "D", "E", "F", "G", "J", "M", "S"]
        let key = segment.replacingOccurrences(of: " Segment", with: "").replacingOccurrences(of: " segment", with: "").trimmingCharacters(in: .whitespaces).uppercased()
        if key == "SUV" { return sira.firstIndex(of: "J").map { $0 + 1 } ?? 0 }
        return sira.firstIndex(of: key).map { $0 + 1 } ?? 0
    }
}
