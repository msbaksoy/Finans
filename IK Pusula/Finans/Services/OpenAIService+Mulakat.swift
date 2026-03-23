// ================================================================
// OpenAIService+Mulakat.swift
// ================================================================
// Mülakat simülasyonu için OpenAI prompt'ları (sorular, değerlendirme, rapor)
// ================================================================

import Foundation

extension OpenAIService {

    // MARK: ─── 1. SORULAR ÜRET (Soru-Cevap & Senaryo modları) ───

    func fetchMulakatSorulari(
        pozisyon: String,
        sirket: String,
        sektor: String,
        mod: MulakatModu,
        adet: Int
    ) async throws -> [MulakatSoru] {

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = makeRequest(url: url)

        let sirketBilgi = sirket.isEmpty ? "" : " Hedef şirket: \(sirket)."
        let sektorOzel = sektorOzelTalimat(sektor: sektor, pozisyon: pozisyon)

        let modTalimat: String
        let kategoriler: String
        switch mod {
        case .soruCevap:
            modTalimat = "Davranışsal, motivasyon ve pozisyona özgü teknik sorular sor."
            kategoriler = "davranissal, motivasyon, teknik, liderlik, iletisim"
        case .senaryo:
            modTalimat = "Gerçek iş vakası senaryoları ver. STAR metoduyla çözülebilecek, karmaşık vakalar olsun."
            kategoriler = "senaryo, liderlik, davranissal, teknik"
        case .tamSimulasyon:
            modTalimat = "Karma sorular: teknik derinlik, zor davranışsal, motivasyon ve kriz yönetimi."
            kategoriler = "teknik, davranissal, motivasyon, liderlik, senaryo, iletisim"
        }

        let systemPrompt = """
        Sen \(sektor) sektöründe 15 yıllık deneyimi olan üst düzey bir İK uzmanısın.
        \(sirket.isEmpty ? "" : "\(sirket) şirketinde işe alım yapıyorsun.")
        \(pozisyon) pozisyonu için GERÇEKTEN ZORLU, klişe olmayan mülakat soruları üretiyorsun.

        KRİTİK KURALLAR:
        - "Kendinizi anlatın", "Neden burada çalışmak istiyorsunuz?" gibi klişeleri ASLA kullanma
        - Her soru pozisyona ve sektöre özgü olsun
        - Teknik sorular gerçek iş bilgisi gerektirsin
        - Davranışsal sorular spesifik durum gerektirsin (genel değil)
        - Senaryo soruları çok boyutlu ve belirsizlik içersin

        \(sektorOzel)

        SADECE JSON döndür:
        [
          {
            "siraNo": 1,
            "soru": "soru metni",
            "kategori": "davranissal|teknik|motivasyon|senaryo|liderlik|iletisim"
          }
        ]
        """

        let userPrompt = """
        Pozisyon: \(pozisyon)
        Sektör: \(sektor)\(sirketBilgi)
        Mod: \(modTalimat)
        Kullanılabilecek kategoriler: \(kategoriler)
        Soru sayısı: \(adet)

        Bu pozisyon için \(adet) adet güçlü, özgün, zorlu mülakat sorusu üret.
        \(mod == .senaryo ? "Her soru gerçek hayat vakası formatında olsun. 'X durumunda ne yapardın?' değil, 'Geçen yıl ekibindeki bir çalışan...' formatında somut senaryo." : "")
        Sadece JSON döndür.
        """

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user",   "content": userPrompt]
            ],
            "temperature": 0.85,
            "max_tokens": 2500
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let json = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        let raw = json.choices.first?.message.content ?? "[]"

        // JSON temizle
        let temiz = raw
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        struct RawSoru: Codable {
            var siraNo: Int
            var soru: String
            var kategori: String
        }

        let rawSorular = try JSONDecoder().decode([RawSoru].self, from: temiz.data(using: .utf8) ?? Data())

        return rawSorular.map { r in
            let kat = MulakatSoruKategorisi(rawValue: r.kategori) ?? .davranissal
            return MulakatSoru(siraNo: r.siraNo, soru: r.soru, kategori: kat)
        }
    }

    // MARK: ─── 2. YANIT DEĞERLENDİR ───────────────────────────────

    func fetchYanitDegerlendirme(
        soru: String,
        yanit: String,
        mod: MulakatModu,
        pozisyon: String,
        kategori: MulakatSoruKategorisi
    ) async throws -> YanitDegerlendirme {

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = makeRequest(url: url)

        let yanitUzunluk = yanit.count
        let yanitKisaUyari = yanitUzunluk < 100
            ? "UYARI: Cevap çok kısa (\(yanitUzunluk) karakter). Bu bir zayıflık."
            : ""

        let starTalimat = (mod == .senaryo || kategori == .senaryo || kategori == .davranissal) ? """
        "starAnaliz": {
          "durum": "Cevabın 'Durum' bileşeni (bağlam/context) — varsa aktar, yoksa 'Belirtilmedi'",
          "gorev": "Cevabın 'Görev' bileşeni (sorumluluk ne idi) — varsa aktar, yoksa 'Belirtilmedi'",
          "eylem": "Cevabın 'Eylem' bileşeni (ne yaptı) — varsa aktar, yoksa 'Belirtilmedi'",
          "sonuc": "Cevabın 'Sonuç' bileşeni (ne elde etti, ölçülebilir mi) — varsa aktar, yoksa 'Belirtilmedi'",
          "eksikBileskenler": ["Eksik olan STAR bileşenleri listesi — boşsa []"]
        },
        """ : """
        "starAnaliz": null,
        """

        let systemPrompt = """
        Sen \(pozisyon) pozisyonu için mülakat koçusun. Bir adayın cevabını değerlendiriyorsun.

        DEĞERLENDİRME KRİTERLERİ:
        - Cevap spesifik mi, soyut mu?
        - Somut örnek var mı, yoksa genel ifade mi?
        - Sonuç/etki ölçülebilir mi?
        - \(kategori == .teknik ? "Teknik derinlik yeterli mi, kavramları doğru kullanıyor mu?" : "")
        - \(kategori == .liderlik ? "Liderlik etkisi ve insan yönetimi somutlaştırılmış mı?" : "")
        - Cevap uzunluğu uygun mu?

        YORUM KURALLARI:
        - Genel övgü YASAK: "Güzel cevap", "Harika" gibi boş ifadeler kullanma
        - Somut eksiklik veya güçlü nokta belirt
        - Örnek: "SGK formülünü doğru uyguladınız fakat enflasyon etkisini hesaba katmadınız"
        - Öneri somut adım içermeli: "Şu soruya cevap verirken şu formatı dene..."
        \(yanitKisaUyari)

        SADECE JSON döndür:
        {
          "puan": 7.5,
          "yorum": "2-3 cümle SOMUT değerlendirme — ne iyi, ne eksik",
          "oneri": "2-3 somut, uygulanabilir iyileştirme önerisi",
          \(starTalimat)
          "dummy": null
        }
        puan: 0-10, ondalıklı olabilir. Türkçe yaz.
        """

        let userPrompt = """
        Pozisyon: \(pozisyon)
        Kategori: \(kategori.rawValue)
        Soru: \(soru)

        Adayın cevabı:
        \(yanit.isEmpty ? "[Boş cevap — cevap vermedi veya atladı]" : yanit)

        Bu cevabı değerlendir. Sadece JSON döndür.
        """

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user",   "content": userPrompt]
            ],
            "temperature": 0.35,
            "max_tokens": 1000
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let json = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        let raw = json.choices.first?.message.content ?? "{}"
        let temiz = raw
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        struct RawDegerlendirme: Codable {
            var puan: Double
            var yorum: String
            var oneri: String
            var starAnaliz: STARAnaliz?
        }

        let raw2 = try JSONDecoder().decode(RawDegerlendirme.self, from: temiz.data(using: .utf8) ?? Data())
        return YanitDegerlendirme(
            puan: raw2.puan,
            yorum: raw2.yorum,
            oneri: raw2.oneri,
            starAnaliz: raw2.starAnaliz
        )
    }

    // MARK: ─── 3. FİNAL RAPOR ──────────────────────────────────────

    func fetchFinalRapor(
        sorular: [MulakatSoru],
        pozisyon: String,
        sirket: String,
        sektor: String,
        mod: MulakatModu
    ) async throws -> MulakatFinalRapor {

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = makeRequest(url: url)

        let soruOzeti = sorular.map { s in
            """
            Soru \(s.siraNo) [\(s.kategori.rawValue)]: \(s.soru)
            Yanıt: \(s.kullaniciYaniti.prefix(400).isEmpty ? "[Boş]" : String(s.kullaniciYaniti.prefix(400)))
            Puan: \(s.aiPuani.map { String(format: "%.1f", $0) } ?? "—")/10
            """
        }.joined(separator: "\n\n")

        let systemPrompt = """
        Sen \(sektor) sektöründe uzman bir kariyer koçusun.
        \(pozisyon) pozisyonuna aday olan kişinin mülakat performansını bütünsel değerlendiriyorsun.

        DEĞERLENDİRME PRENSİPLERİ:
        - Genel puan adil olsun: ortalama 7+ sadece gerçekten güçlü cevaplara
        - Güçlü yönler: "iyi iletişim" değil somut örnek: "3. soruda vaka senaryosunu STAR metoduyla tam kurdu"
        - Geliştirilecek: spesifik, uygulanabilir: "Teknik sorularda formül/rakam kullanmak güçlendirir"
        - Sektör özelinde öneri ekle: \(sektor) sektöründe önemli yetkinlikler neler?

        SADECE JSON döndür:
        {
          "genelPuan": 7.2,
          "genelYorum": "3-4 cümle. Performans özeti + bir güçlü yön + bir kritik gelişim alanı.",
          "gucluYonler": [
            "Güçlü yön 1 — somut örnekle",
            "Güçlü yön 2 — somut örnekle",
            "Güçlü yön 3 — somut örnekle"
          ],
          "gelistirilecek": [
            "Gelişim alanı 1 — nasıl iyileştirilebilir",
            "Gelişim alanı 2 — nasıl iyileştirilebilir",
            "Gelişim alanı 3 — nasıl iyileştirilebilir"
          ]
        }
        Türkçe yaz.
        """

        let sirketBilgi = sirket.isEmpty ? "" : " (Hedef: \(sirket))"
        let userPrompt = """
        Pozisyon: \(pozisyon)\(sirketBilgi)
        Sektör: \(sektor)
        Mülakat Modu: \(mod.rawValue)

        Mülakat detayı:
        \(soruOzeti)

        Bu adayın performansını değerlendir. Sadece JSON döndür.
        """

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user",   "content": userPrompt]
            ],
            "temperature": 0.4,
            "max_tokens": 1200
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let json = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        let raw = json.choices.first?.message.content ?? "{}"
        let temiz = raw
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        struct RawRapor: Codable {
            var genelPuan: Double
            var genelYorum: String
            var gucluYonler: [String]
            var gelistirilecek: [String]
        }

        let raw2 = try JSONDecoder().decode(RawRapor.self, from: temiz.data(using: .utf8) ?? Data())
        return MulakatFinalRapor(
            genelPuan: raw2.genelPuan,
            genelYorum: raw2.genelYorum,
            gucluYonler: raw2.gucluYonler,
            gelistirilecek: raw2.gelistirilecek
        )
    }

    // MARK: ─── 4. SİMÜLASYON: KARŞILAMA ───────────────────────────

    func fetchMulakatKarsilama(
        pozisyon: String,
        sirket: String,
        sektor: String
    ) async throws -> String {

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = makeRequest(url: url)

        let sirketBilgi = sirket.isEmpty ? "bir teknoloji şirketi" : sirket
        let systemPrompt = """
        Sen \(sirketBilgi)'ta \(pozisyon) pozisyonu için mülakat yapan kıdemli bir İK uzmanısın.
        Gerçekçi, biraz resmi ama sıcak bir ton kullan.
        Türkçe yaz. Kısa tut (3-4 cümle toplam).
        Kendini kısaca tanıt, pozisyonu bir cümleyle özetle, mülakatın yapısını açıkla.
        Ardından ilk soruyu sor — ZORLU, klişe olmayan bir soru olsun.
        """

        let userPrompt = "Mülakatı başlat ve ilk soruyu sor. Pozisyon: \(pozisyon), Sektör: \(sektor)."

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user",   "content": userPrompt]
            ],
            "temperature": 0.7,
            "max_tokens": 400
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let json = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        return json.choices.first?.message.content?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    // MARK: ─── 5. SİMÜLASYON: KONUŞMA DEVAMI ─────────────────────

    func fetchSimulasyonCevap(
        gecmis: [KonusmaMesaji],
        pozisyon: String,
        sirket: String,
        sektor: String
    ) async throws -> String {

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = makeRequest(url: url)

        let systemPrompt = """
        Sen \(sirket.isEmpty ? "bir şirkette" : "\(sirket)'ta") \(pozisyon) pozisyonu için mülakat yapan kıdemli İK uzmanısın.

        DAVRANIŞ KURALLARI:
        - Adayın cevabı muğlak veya kısa ise takip et: "Bunu biraz daha açabilir misiniz?"
        - Adayın cevabı tatmin edici değilse farklı bir açıdan sor
        - Zaman zaman baskı uygula: "Bu durumda üst yönetiminiz size katılmıyorsa ne yapardınız?"
        - Teknik cevaplarda derinleş: "Peki bu çözümün ölçeklenebilirlik sorunu nasıl aşıldı?"
        - Klişe cevaplar gelirse nazikçe zorla: "Daha somut bir örnek verebilir misiniz?"

        Toplam 6-8 mesaj sonra mülakatı nazikçe bitir.
        Bitirirken cevabının SONUNA tam olarak [MULAKAT_BITTI] yaz.
        Türkçe konuş. Her mesaj 2-4 cümle.
        """

        var messages: [[String: String]] = [["role": "system", "content": systemPrompt]]
        for mesaj in gecmis {
            let rol = mesaj.rol == .ai ? "assistant" : "user"
            messages.append(["role": rol, "content": mesaj.icerik])
        }

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 500
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let json = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        return json.choices.first?.message.content?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    // MARK: ─── 6. SİMÜLASYON: FİNAL RAPOR ───────────────────────

    func fetchSimulasyonRaporu(
        gecmis: [KonusmaMesaji],
        pozisyon: String,
        sirket: String,
        sektor: String
    ) async throws -> MulakatFinalRapor {

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = makeRequest(url: url)

        let konusmaMetni = gecmis.map { m in
            "\(m.rol == .ai ? "İK" : "Aday"): \(m.icerik)"
        }.joined(separator: "\n")

        let systemPrompt = """
        Sen \(sektor) sektöründe uzman bir mülakat koçusun.
        Tamamlanan mülakat konuşmasını analiz ediyorsun.

        DEĞERLENDİR:
        - Adayın iletişim tarzı, özgüveni, hazırlık düzeyi
        - Teknik yetkinlik göstergesi (sektöre özel)
        - Sorulara verilen cevapların kalitesi ve derinliği
        - Takip sorularına verilen tepkiler

        SADECE JSON döndür:
        {
          "genelPuan": 7.5,
          "genelYorum": "3-4 cümle. Performans özeti, güçlü nokta, kritik gelişim.",
          "gucluYonler": ["somut 1", "somut 2", "somut 3"],
          "gelistirilecek": ["spesifik 1", "spesifik 2", "spesifik 3"]
        }
        """

        let userPrompt = """
        Pozisyon: \(pozisyon), Şirket: \(sirket.isEmpty ? "belirtilmedi" : sirket)
        Sektör: \(sektor)

        Mülakat konuşması:
        \(konusmaMetni.prefix(4000))

        Değerlendir. Sadece JSON döndür.
        """

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user",   "content": userPrompt]
            ],
            "temperature": 0.4,
            "max_tokens": 900
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let json = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        let raw = json.choices.first?.message.content ?? "{}"
        let temiz = raw
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        struct RawRapor: Codable {
            var genelPuan: Double
            var genelYorum: String
            var gucluYonler: [String]
            var gelistirilecek: [String]
        }

        let raw2 = try JSONDecoder().decode(RawRapor.self, from: temiz.data(using: .utf8) ?? Data())
        return MulakatFinalRapor(
            genelPuan: raw2.genelPuan,
            genelYorum: raw2.genelYorum,
            gucluYonler: raw2.gucluYonler,
            gelistirilecek: raw2.gelistirilecek
        )
    }

    // MARK: ─── Sektör özel talimatlar ─────────────────────────

    private func sektorOzelTalimat(sektor: String, pozisyon: String) -> String {
        let lower = sektor.lowercased()

        if lower.contains("finans") || lower.contains("banka") || lower.contains("muhaseb") {
            return """
            SEKTÖR TALİMATI (Finans/Bankacılık):
            - Teknik sorular: finansal analiz, risk değerlendirme, düzenleyici uyum (BDDK, SPK), Excel/VBA kullanımı
            - Davranışsal: etik ikilemler, hata raporlama kültürü, üst baskısı altında karar alma
            - Senaryo: kredi riski, fraud tespiti, müşteri şikayeti yönetimi örnekleri
            """
        } else if lower.contains("teknoloji") || lower.contains("yazılım") || lower.contains("it") {
            return """
            SEKTÖR TALİMATI (Teknoloji/Yazılım):
            - Teknik sorular: mimari kararlar, kod kalitesi, teknik borç yönetimi, ölçeklenebilirlik
            - Davranışsal: üretim ortamı krizi, takım içi teknik anlaşmazlık, deadline baskısı
            - Senaryo: sistem çöküşü, güvenlik açığı, yanlış tahmini olan proje
            """
        } else if lower.contains("pazarlama") || lower.contains("satış") || lower.contains("ticaret") {
            return """
            SEKTÖR TALİMATI (Pazarlama/Satış):
            - Teknik sorular: CAC/LTV hesabı, funnel optimizasyonu, A/B testi yorumlama, CRM kullanımı
            - Davranışsal: hedefi tutturamama, müşteri reddi, rekabet analizi
            - Senaryo: ürün lansmanı krizi, rakip fiyat kırması, sosyal medya krizi
            """
        } else if lower.contains("insan kaynak") || lower == "ik" || lower.contains("human resources") {
            return """
            SEKTÖR TALİMATI (İnsan Kaynakları):
            - Teknik: işveren markası oluşturma, performans değerlendirme sistemleri, iş hukuku
            - Davranışsal: çalışan şikayeti, kötü performans yönetimi, üst yönetimle çatışma
            - Senaryo: toplu işten çıkarma iletişimi, kültür uyumsuzluğu, bütçe kısıtı
            """
        } else if lower.contains("sağlık") || lower.contains("eczane") || lower.contains("hastane") {
            return """
            SEKTÖR TALİMATI (Sağlık):
            - Teknik: protokol uygulama, hasta güvenliği, raporlama standartları
            - Davranışsal: acil durum kararı, hasta ailesi iletişimi, ekip içi çatışma
            - Senaryo: kaynak kıtlığı, kritik hata raporlama, iş yükü yönetimi
            """
        } else {
            return """
            SEKTÖR TALİMATI (\(sektor)):
            - \(pozisyon) pozisyonuna özgü teknik bilgi gerektiren sorular sor
            - Sektörün spesifik zorluklarına yönelik senaryolar kullan
            - Liderlik ve iletişim sorularını sektör bağlamına oturt
            """
        }
    }
}
