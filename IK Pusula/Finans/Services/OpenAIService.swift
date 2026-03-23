// ================================================================
// OpenAIService.swift — PROMPT MÜHENDİSLİĞİ TAM REVİZYONU
// ================================================================
// API key, model ve response parsing değişmedi;
// system prompt + user prompt mantığı revize edildi.
// ================================================================

import Foundation

class OpenAIService {
    static let shared = OpenAIService()

    /// Build ayarı + Info.plist: `OPENAI_API_KEY` (bkz. `Config/APIKeys.xcconfig`).
    /// Geliştirme sırasında ortam değişkeni `OPENAI_API_KEY` de okunur.
    internal var apiKey: String {
        if let k = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String,
           !k.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return k.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let e = ProcessInfo.processInfo.environment["OPENAI_API_KEY"],
           !e.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return e.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return ""
    }

    // MARK: - Yardımcı: para formatlayıcı
    private func fp(_ v: Double) -> String {
        guard v > 0 else { return "belirtilmemiş" }
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        f.locale = Locale(identifier: "tr_TR")
        let s = f.string(from: NSNumber(value: v)) ?? "\(Int(v))"
        return "₺\(s)"
    }

    private func pct(_ base: Double, _ yeni: Double) -> String {
        guard base > 0 else { return "—" }
        let oran = (yeni - base) / base * 100
        let isaret = oran >= 0 ? "+" : ""
        return "\(isaret)\(String(format: "%.0f", oran))%"
    }

    // MARK: ─── 1. HIZLI ANALİZ (KiyaslamaAnalysisView) ──────────
    func fetchCareerAdvice(
        draft: TeklifKiyaslama,
        mevcutYillikNet: Double = 0,
        teklifYillikNet: Double = 0
    ) async throws -> String {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = makeRequest(url: url)

        // ── Finansal bağlam ──────────────────────────────────────
        let maasArtisOrani = pct(mevcutYillikNet, teklifYillikNet)
        let maasArtisVarMi = teklifYillikNet > mevcutYillikNet
        let terfiVarMi = draft.terfiVarMi

        // ── Yan hak delta özeti (sadece değişen kalemleri yaz) ──
        var yaHakDelta: [String] = []

        // Sigorta değişimi
        let mSig = draft.mevcutSigortaTipi
        let tSig = draft.teklifSigortaTipi
        if mSig != tSig {
            let mLabel = sigortaLabel(mSig)
            let tLabel = sigortaLabel(tSig)
            if sigortaRank(tSig) > sigortaRank(mSig) {
                yaHakDelta.append("Sigorta yükseliyor (\(mLabel) → \(tLabel))")
            } else if sigortaRank(tSig) < sigortaRank(mSig) {
                yaHakDelta.append("Sigorta geriliyor (\(mLabel) → \(tLabel))")
            }
        }

        // Yemek değişimi
        let mYemek = draft.mevcutYemekTipi
        let tYemek = draft.teklifYemekTipi
        if mYemek != tYemek {
            if tYemek == "Yok" || tYemek.isEmpty {
                yaHakDelta.append("Yemek desteği kaybediliyor (\(mYemek) → Yok)")
            } else if mYemek == "Yok" || mYemek.isEmpty {
                yaHakDelta.append("Yemek desteği kazanılıyor (Yok → \(tYemek))")
            } else {
                yaHakDelta.append("Yemek tipi değişiyor (\(mYemek) → \(tYemek))")
            }
        }

        // Araç değişimi
        let mArac = draft.mevcutAracSegment
        let tArac = draft.teklifAracSegment
        let mAracVar = !mArac.isEmpty && mArac.lowercased() != "yok"
        let tAracVar = !tArac.isEmpty && tArac.lowercased() != "yok"
        if mAracVar && !tAracVar {
            yaHakDelta.append("Şirket aracı (\(mArac)) kaybediliyor")
        } else if !mAracVar && tAracVar {
            yaHakDelta.append("Şirket aracı kazanılıyor (\(tArac))")
        } else if mAracVar && tAracVar && mArac != tArac {
            yaHakDelta.append("Araç segmenti değişiyor (\(mArac) → \(tArac))")
        }

        // Çalışma modeli değişimi
        let mModel = draft.mevcutCalismaModeli
        let tModel = draft.teklifCalismaModeli
        if mModel != tModel && !mModel.isEmpty && !tModel.isEmpty {
            yaHakDelta.append("Çalışma modeli değişiyor (\(mModel) → \(tModel))")
        }

        let deltaOzet = yaHakDelta.isEmpty
            ? "Yan haklarda kayda değer bir değişiklik yok."
            : yaHakDelta.joined(separator: "; ") + "."

        // ── System prompt ────────────────────────────────────────
        let systemPrompt = """
        Sen 15 yıllık tecrübeli bir İnsan Kaynakları Direktörü ve Kariyer Koçusun.
        Senden istenen; bir çalışanın aldığı yeni iş teklifini, sadece yan hakları değil \
        bütünüyle değerlendirmen.

        TEMEL KURALLAR — bunlara kesinlikle uy:

        1. TOPLAM PAKETİ ÖN PLANA AL. Finansal analiz yaparken her zaman \
        "gerçek yıllık toplam paket" rakamını temel al. Bir kalem sıfır olsa da \
        toplam paket iyiyse bunu olumlu bir çerçevede sun.

        2. SIFIR = SORUN DEĞİL. Gizli servet, yan hak veya herhangi bir kalem \
        sıfır ya da boşsa, bunu olumsuz bir bulgu olarak öne çıkarma. \
        Ancak karşı tarafta bu kalem varsa ve maaş bunu telafi etmiyorsa söyle.

        3. ORANTILILIK. Küçük bir yan hak kaybını büyük bir maaş artışıyla \
        kıyaslıyorsan gerçekçi ol. "Yemek desteği yok ama zam %40" gibi durumlarda \
        yemeği sorun olarak sunma; tersine maaşın bunu fazlasıyla kapattığını belirt.

        4. SADECE FARK EDEN ŞEYLERİ ANLAT. Değişmeyen kalemleri tekrar etme. \
        Şirketten şirkete değişen unsurlar neyse onlara odaklan.

        5. NET VE CESUR OL. 2-3 kısa paragraf yaz. Samimi "sen" dili kullan. \
        Son paragrafta "bu şartlarda geçmek/kalmak daha mantıklı" şeklinde \
        net ama baskısız bir yönlendirme yap.

        6. YORUM YAP, VERİYİ TEKRAR ETME. Rakamları iki kez söyleme; \
        anlamını yorumla.
        """

        // ── User prompt ──────────────────────────────────────────
        let userPrompt = """
        [FİNANSAL ÖZET]
        • Mevcut yıllık net paket (maaş + prim): \(fp(mevcutYillikNet))
        • Yeni teklif yıllık net paket (maaş + prim): \(fp(teklifYillikNet))
        • Finansal değişim: \(maasArtisOrani) (\(maasArtisVarMi ? "artış" : "azalış"))
        \(terfiVarMi ? "• Bu geçişte terfi var: Daha yüksek bir unvana geçiş söz konusu." : "• Bu yatay bir geçiş: Unvan değişmiyor.")

        [YAN HAK DEĞİŞİKLİKLERİ — sadece değişenler]
        \(deltaOzet)

        [MEVCUT İŞ]
        • Unvan: \(draft.mevcutUnvan.isEmpty ? "belirtilmedi" : draft.mevcutUnvan) \
        (\(draft.mevcutUnvanYil) yıldır bu rolde)
        • Çalışma Modeli: \(mModel.isEmpty ? "belirtilmedi" : mModel)
        • Şirket Ölçeği: \(draft.mevcutSirketOlcegi.isEmpty ? "belirtilmedi" : draft.mevcutSirketOlcegi)

        [YENİ TEKLİF]
        • Unvan: \(draft.teklifUnvan.isEmpty ? "belirtilmedi" : draft.teklifUnvan)
        • Çalışma Modeli: \(tModel.isEmpty ? "belirtilmedi" : tModel)
        • Şirket Ölçeği: \(draft.teklifSirketOlcegi.isEmpty ? "belirtilmedi" : draft.teklifSirketOlcegi)

        Lütfen:
        - Finansal tabloya ve kariyer boyutuna birlikte odaklan.
        - Yan haklardaki değişimleri, maaş artışının onları karşılayıp \
        karşılamadığı bağlamında değerlendir.
        - Son paragrafta net ama baskısız bir yönlendirme yap.
        """

        return try await send(request: &request, system: systemPrompt, user: userPrompt)
    }

    // MARK: ─── 2. DERİN ANALİZ (DeepKiyaslamaAnalysisView) ──────
    func fetchDeepDiveAdvice(
        draft: TeklifKiyaslama,
        currentTrue: Double,
        offerTrue: Double,
        currentHidden: Double,
        offerHidden: Double,
        kidemRisk: Double
    ) async throws -> String {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = makeRequest(url: url)

        // ── Türetilmiş bilgiler ──────────────────────────────────
        let toplamArtisOrani = pct(currentTrue, offerTrue)
        let toplamArtisVarMi = offerTrue > currentTrue
        let toplamFark = offerTrue - currentTrue

        // Maaş kısmı (gizli servet hariç)
        let mevcutMaasKismi = currentTrue - currentHidden
        let teklifMaasKismi = offerTrue - offerHidden
        let maasArtisOrani = pct(mevcutMaasKismi, teklifMaasKismi)

        // Gizli servet bağlamı
        let gizliServetVarMi = currentHidden > 0 || offerHidden > 0
        let gizliServetFark = offerHidden - currentHidden

        // Kıdem: amortisman süresi
        let amortismanAy: Double
        let aylikArtis = toplamFark / 12
        if aylikArtis > 0 && kidemRisk > 0 {
            amortismanAy = kidemRisk / aylikArtis
        } else {
            amortismanAy = 0
        }

        let amortismanMetni: String
        if kidemRisk <= 0 {
            amortismanMetni = "Kıdem tazminatı riski yok (1 yıldan az çalışılmış)."
        } else if aylikArtis <= 0 {
            amortismanMetni = "Teklif mevcut paketi aşmıyor, kıdem tazminatı \(fp(kidemRisk)) yıllara bırakılıyor."
        } else if amortismanAy <= 6 {
            amortismanMetni = "Kıdem tazminatı (\(fp(kidemRisk))) yaklaşık \(Int(amortismanAy)) ayda amorti oluyor — çok hızlı."
        } else if amortismanAy <= 18 {
            amortismanMetni = "Kıdem tazminatı (\(fp(kidemRisk))) yaklaşık \(String(format: "%.1f", amortismanAy/12)) yılda amorti oluyor — makul."
        } else {
            amortismanMetni = "Kıdem tazminatı (\(fp(kidemRisk))) amortisman süresi \(String(format: "%.1f", amortismanAy/12)) yıl — uzun, dikkat gerektirir."
        }

        // Yan hak kıyaslaması — sadece gerçekten farklılaşan kalemleri ekle
        var yanHakNot: [String] = []

        let mSig = draft.mevcutSigortaTipi; let tSig = draft.teklifSigortaTipi
        if mSig != tSig {
            let delta = sigortaRank(tSig) - sigortaRank(mSig)
            if delta > 0 { yanHakNot.append("Sigorta iyileşiyor (\(sigortaLabel(mSig)) → \(sigortaLabel(tSig)))") }
            else if delta < 0 { yanHakNot.append("Sigorta zayıflıyor (\(sigortaLabel(mSig)) → \(sigortaLabel(tSig)))") }
        }

        let mYemek = draft.mevcutYemekTipi; let tYemek = draft.teklifYemekTipi
        if mYemek != tYemek {
            if (tYemek == "Yok" || tYemek.isEmpty) && !(mYemek == "Yok" || mYemek.isEmpty) {
                yanHakNot.append("Yemek desteği kaybediliyor")
            } else if !(tYemek == "Yok" || tYemek.isEmpty) && (mYemek == "Yok" || mYemek.isEmpty) {
                yanHakNot.append("Yemek desteği kazanılıyor (\(tYemek))")
            }
        }

        let mArac = draft.mevcutAracSegment; let tArac = draft.teklifAracSegment
        let mAracVar = !mArac.isEmpty && mArac.lowercased() != "yok"
        let tAracVar = !tArac.isEmpty && tArac.lowercased() != "yok"
        if mAracVar && !tAracVar { yanHakNot.append("Şirket aracı (\(mArac)) kaybediliyor") }
        else if !mAracVar && tAracVar { yanHakNot.append("Şirket aracı kazanılıyor (\(tArac))") }
        else if mAracVar && tAracVar && mArac != tArac { yanHakNot.append("Araç segmenti değişiyor (\(mArac) → \(tArac))") }

        let mModel = draft.mevcutCalismaModeli; let tModel = draft.teklifCalismaModeli
        if mModel != tModel && !mModel.isEmpty && !tModel.isEmpty {
            yanHakNot.append("Çalışma modeli değişiyor (\(mModel) → \(tModel))")
        }

        let izinFark = draft.teklifYillikIzin - draft.mevcutYillikIzin
        if abs(izinFark) >= 3 {
            yanHakNot.append(izinFark > 0
                ? "Yıllık izin \(izinFark) gün artıyor"
                : "Yıllık izin \(abs(izinFark)) gün azalıyor")
        }

        let yanHakOzet = yanHakNot.isEmpty
            ? "Yan haklarda anlamlı bir değişiklik tespit edilmedi."
            : yanHakNot.joined(separator: "; ") + "."

        // ── System prompt ────────────────────────────────────────
        let systemPrompt = """
        Sen 15 yıllık deneyimli bir İnsan Kaynakları Direktörü ve Kariyer Koçusun.
        Bir çalışana iş teklifi konusunda stratejik, dürüst ve bütünleşik bir \
        değerlendirme yapacaksın.

        MUTLAKA UYMASI GEREKEN KURALLAR:

        1. TOPLAM PAKET ODAKLI OL. Her zaman "gerçek yıllık toplam paket" rakamını \
        (maaş + prim + tüm yan haklar dahil) değerlendirmenin merkezi yap. \
        Tek tek kalemler birer renk — tek başlarına anlam taşımazlar.

        2. SIFIR VE BOŞ ALANLARI SORUN OLARAK SUNMA. Gizli servet, yan hak veya \
        herhangi bir kalem sıfır ya da boşsa bu veriyi yok say. Sadece iki taraf \
        arasında gerçek bir fark varsa ve bu fark toplamı anlamlı biçimde etkiliyor\
        sa bahset.

        3. ORANTILILIK İLKESİ. Küçük bir yan hak kaybı varsa ama toplam paket \
        anlamlı biçimde artıyorsa, bu kaybı önemsizleştir veya hiç bahsetme. \
        Büyük finansal kazanımı öne çıkar. Tersine, büyük bir yan hak kaybı maaş \
        artışını eritiyorsa bunu açıkça söyle.

        4. SADECE FARK EDEN KALEMLERİ ANLAT. Değişmeyen unsurlara zaman harcama.

        5. KARIYER BOYUTUNU UNUTMA. Terfi varsa piyasa değeri, yeni yetkinlikler, \
        CV etkisi ve uzun vadeli kazanımı mutlaka konuştur. Kıdem tazminatı \
        riskini amortisman süresiyle birlikte yorumla — bir risk değil, yatırım \
        süresi olarak çerçevele.

        6. ÇIKTI KURALLARI:
           - Türkçe, 3 kısa paragraf, samimi "sen" dili
           - Rakamları TEKRAR ETME; anlamını yorumla
           - Son paragrafta net ama baskısız bir öneri sun
           - Madde madde liste yapma; akıcı paragraflar yaz
        """

        // ── User prompt ──────────────────────────────────────────
        var userPromptParts: [String] = []

        userPromptParts.append("""
        [TOPLAM PAKET KARŞILAŞTIRMASI]
        • Mevcut gerçek yıllık paket: \(fp(currentTrue))
        • Yeni teklif gerçek yıllık paket: \(fp(offerTrue))
        • Toplam değişim: \(toplamArtisOrani) (\(toplamArtisVarMi ? "artış" : "azalış"))
        • Maaş + Prim değişimi (yan haklar hariç): \(maasArtisOrani)
        """)

        if gizliServetVarMi {
            var gizliNot = "• Gizli servet (araç, BES, yemek, sigorta vb.): Mevcut \(fp(currentHidden)) / Teklif \(fp(offerHidden))"
            if abs(gizliServetFark) < 5000 {
                gizliNot += " — fark önemsiz, toplam pakete etkisi minimal."
            } else if gizliServetFark < 0 {
                gizliNot += " — gizli servet \(fp(abs(gizliServetFark))) azalıyor; ancak bu maaş artışının içinde değerlendirilebilir."
            } else {
                gizliNot += " — gizli servet \(fp(gizliServetFark)) artıyor, paketi daha da güçlendiriyor."
            }
            userPromptParts.append(gizliNot)
        }

        userPromptParts.append("""

        [KIDEM TAZMİNATI]
        • \(amortismanMetni)
        """)

        userPromptParts.append("""

        [YAN HAK DEĞİŞİKLİKLERİ]
        • \(yanHakOzet)
        """)

        userPromptParts.append("""

        [KARİYER ÇAPI]
        Mevcut: \(draft.mevcutUnvan.isEmpty ? "belirtilmedi" : draft.mevcutUnvan), \
        \(draft.mevcutUnvanYil) yıl kıdem, \
        \(draft.mevcutCalismaModeli.isEmpty ? "model belirtilmedi" : draft.mevcutCalismaModeli), \
        \(draft.mevcutSirketOlcegi.isEmpty ? "ölçek belirtilmedi" : draft.mevcutSirketOlcegi)
        Teklif: \(draft.teklifUnvan.isEmpty ? "belirtilmedi" : draft.teklifUnvan), \
        \(draft.teklifCalismaModeli.isEmpty ? "model belirtilmedi" : draft.teklifCalismaModeli), \
        \(draft.teklifSirketOlcegi.isEmpty ? "ölçek belirtilmedi" : draft.teklifSirketOlcegi)
        \(draft.terfiVarMi ? "• Bu geçiş bir terfi içeriyor." : "• Yatay geçiş — unvan değişmiyor.")
        """)

        userPromptParts.append("""

        Bu verilere dayanarak stratejik, bütünleşik ve dürüst bir değerlendirme yap.
        Toplamın net olarak iyiye gittiğini ya da kötüye gittiğini merkeze al;
        yan hak detaylarını yalnızca büyük resmi etkileyen ölçüde konuştur.
        """)

        let userPrompt = userPromptParts.joined(separator: "\n")

        return try await send(request: &request, system: systemPrompt, user: userPrompt)
    }

    // MARK: ─── 3. CV ÖZETİ (değişmedi) ─────────────────────────
    func generateCVSummary(adSoyad: String, unvanlar: [String], okullar: [String]) async throws -> String {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = makeRequest(url: url)

        let userPrompt = """
        Aşağıdaki bilgilere göre bu kişi için Türkçe, 2 veya en fazla 3 cümlelik \
        kısa bir profesyonel CV özeti yaz. Doğal ve öz olsun; jargondan kaçın.
        Ad Soyad: \(adSoyad.isEmpty ? "Belirtilmedi" : adSoyad)
        İş unvanları: \(unvanlar.isEmpty ? "Yok" : unvanlar.joined(separator: ", "))
        Eğitim: \(okullar.isEmpty ? "Belirtilmedi" : okullar.prefix(5).joined(separator: "; "))
        """

        let systemPrompt = "Sen bir CV danışmanısın. Sadece verilen bilgilerden 2-3 cümlelik profesyonel özet yaz. Başka açıklama ekleme."

        return try await send(request: &request, system: systemPrompt, user: userPrompt)
    }

    // MARK: ─── Ortak HTTP Yardımcıları ───────────────────────────
    /// Mülakat extension'ı ve diğer modüller için internal (private değil).
    func makeRequest(url: URL) -> URLRequest {
        var r = URLRequest(url: url)
        r.httpMethod = "POST"
        r.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        r.addValue("application/json", forHTTPHeaderField: "Content-Type")
        return r
    }

    private func send(request: inout URLRequest, system: String, user: String) async throws -> String {
        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": system],
                ["role": "user",   "content": user],
            ],
            "temperature": 0.65,
            "max_tokens": 600
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let json = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        return json.choices.first?.message.content?.trimmingCharacters(in: .whitespacesAndNewlines)
            ?? "Analiz yapılamadı."
    }

    // MARK: ─── Sigorta Yardımcıları ─────────────────────────────
    private func sigortaRank(_ tip: String) -> Int {
        let t = tip.lowercased()
        if t.contains("özel") { return 3 }
        if t.contains("tamamlayıcı") || t == "tss" { return 2 }
        return 1
    }

    private func sigortaLabel(_ tip: String) -> String {
        let t = tip.lowercased()
        if t.contains("özel") { return "ÖSS" }
        if t.contains("tamamlayıcı") { return "TSS" }
        if t.isEmpty || t == "yok" { return "Yok" }
        return tip
    }
}

// MARK: - Response Model (değişmedi)
struct OpenAIResponse: Codable {
    let choices: [Choice]
    struct Choice: Codable {
        let message: Message
    }
    struct Message: Codable {
        let content: String?
    }
}
