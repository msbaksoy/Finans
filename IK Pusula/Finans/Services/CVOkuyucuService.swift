import SwiftUI
import PDFKit
import Vision
import UniformTypeIdentifiers
import UIKit

// MARK: - Parse Edilmis CV Modeli (AI'dan donen JSON)
struct CVParseEdilmis: Codable {
    // Kisisel
    var adSoyad: String?
    var email: String?
    var telefon: String?
    var sehir: String?
    var linkedIn: String?
    var webSitesi: String?
    var dogumYili: String?

    // Icerik
    var ozet: String?
    var isDeneyimleri: [CVDeneyim]?
    var egitimler: [CVEgitim]?
    var yetenekler: [String]?
    var diller: [CVDil]?
    var sertifikalar: [CVSertifika]?
    var projeler: [CVProje]?
    var hobiler: [String]?
}

struct CVDeneyim: Codable {
    var unvan: String?
    var sirket: String?
    var sehir: String?
    var baslangic: String?
    var bitis: String?
    var halaDevamEdiyor: Bool?
    var aciklama: String?
    var sektor: String?
}

struct CVEgitim: Codable {
    var okul: String?
    var bolum: String?
    var derece: String?
    var baslangic: String?
    var bitis: String?
    var not: String?
}

struct CVDil: Codable {
    var ad: String?
    var seviye: String?
}

struct CVSertifika: Codable {
    var ad: String?
    var kurum: String?
    var tarih: String?
}

struct CVProje: Codable {
    var ad: String?
    var aciklama: String?
    var teknolojiler: String?
    var tarih: String?
}

// MARK: - Hata Tipleri
enum CVOkuyucuHata: LocalizedError {
    case desteklenmeyen
    case metinCikarilmadi
    case apiBaglantisi(String)
    case parseHatasi
    case bosCV

    var errorDescription: String? {
        switch self {
        case .desteklenmeyen: return "Desteklenmeyen dosya formati. PDF veya goruntu yukleyin."
        case .metinCikarilmadi: return "Dosyadan metin cikarilamadi. Farkli bir dosya deneyin."
        case .apiBaglantisi(let m): return "AI baglanti hatasi: \(m)"
        case .parseHatasi: return "CV icerigi analiz edilemedi."
        case .bosCV: return "CV icerigi bos gorunuyor."
        }
    }
}

// MARK: - Servis
@MainActor
final class CVOkuyucuService: ObservableObject {
    @Published var durum: Durum = .bekliyor
    @Published var sonuc: CVParseEdilmis? = nil
    @Published var ilerlemeMesaji: String = ""

    enum Durum {
        case bekliyor
        case yukleniyor
        case tamamlandi
        case hata(String)
    }

    // MARK: Ana Fonksiyon
    func cvOku(url: URL) async {
        durum = .yukleniyor
        ilerlemeMesaji = "Dosya okunuyor..."

        do {
            // 1. Metni cikar
            let metin = try await metinCikar(url: url)
            guard !metin.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw CVOkuyucuHata.bosCV
            }

            ilerlemeMesaji = "CV analiz ediliyor..."

            // 2. OpenAI'ya gonder
            let parsed = try await openAIileParse(metin: metin)

            sonuc = parsed
            durum = .tamamlandi
            ilerlemeMesaji = "Tamamlandi"

        } catch let hata as CVOkuyucuHata {
            durum = .hata(hata.localizedDescription)
        } catch {
            durum = .hata(error.localizedDescription)
        }
    }

    // MARK: Metin Cikarma
    private func metinCikar(url: URL) async throws -> String {
        let ext = url.pathExtension.lowercased()

        switch ext {
        case "pdf":
            return try pdfdenMetin(url: url)
        case "jpg", "jpeg", "png", "heic", "heif", "webp":
            return try await gorseldenMetin(url: url)
        default:
            // Uzantisiz veya farkliysa once PDF dene, sonra gorsel
            if let metin = try? pdfdenMetin(url: url), !metin.isEmpty {
                return metin
            }
            return try await gorseldenMetin(url: url)
        }
    }

    // MARK: PDF -> Metin (PDFKit)
    private func pdfdenMetin(url: URL) throws -> String {
        guard let dokuman = PDFDocument(url: url) else {
            throw CVOkuyucuHata.metinCikarilmadi
        }

        var tumMetin = ""
        for i in 0..<min(dokuman.pageCount, 5) { // max 5 sayfa
            if let sayfa = dokuman.page(at: i) {
                tumMetin += (sayfa.string ?? "") + "\n"
            }
        }

        let temiz = tumMetin.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !temiz.isEmpty else {
            // PDF metin icermiyorsa (taranmis olabilir) OCR dene
            throw CVOkuyucuHata.metinCikarilmadi
        }
        return String(temiz.prefix(12000))
    }

    // MARK: Gorsel -> Metin (Vision OCR)
    private func gorseldenMetin(url: URL) async throws -> String {
        try await Task.detached(priority: .userInitiated) {
            let veri = try Data(contentsOf: url)
            guard let uiImage = UIImage(data: veri),
                  let cgImage = uiImage.cgImage else {
                throw CVOkuyucuHata.metinCikarilmadi
            }

            return try await withCheckedThrowingContinuation { devam in
                let istek = VNRecognizeTextRequest { sonuc, hata in
                    if let hata {
                        devam.resume(throwing: CVOkuyucuHata.apiBaglantisi(hata.localizedDescription))
                        return
                    }
                    let metin = (sonuc.results as? [VNRecognizedTextObservation])?
                        .compactMap { $0.topCandidates(1).first?.string }
                        .joined(separator: "\n") ?? ""
                    devam.resume(returning: String(metin.prefix(12000)))
                }
                istek.recognitionLanguages = ["tr-TR", "en-US"]
                istek.recognitionLevel = .accurate
                istek.usesLanguageCorrection = true

                let isleme = VNImageRequestHandler(cgImage: cgImage, options: [:])
                do {
                    try isleme.perform([istek])
                } catch {
                    devam.resume(throwing: CVOkuyucuHata.metinCikarilmadi)
                }
            }
        }.value
    }

    // MARK: OpenAI - CV Parse
    private func openAIileParse(metin: String) async throws -> CVParseEdilmis {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var istek = URLRequest(url: url)
        istek.httpMethod = "POST"
        istek.setValue("application/json", forHTTPHeaderField: "Content-Type")
        istek.setValue("Bearer \(OpenAIService.shared.apiKeyPublic)", forHTTPHeaderField: "Authorization")
        istek.timeoutInterval = 60

        let systemPrompt = """
        Sen bir CV ayristirma uzmansin. Sana verilen CV metninden bilgileri cikar ve SADECE JSON don.

        JSON semasi:
        {
          "adSoyad": "string veya null",
          "email": "string veya null",
          "telefon": "string veya null",
          "sehir": "string veya null",
          "linkedIn": "string veya null",
          "webSitesi": "string veya null",
          "dogumYili": "string veya null",
          "ozet": "string veya null",
          "isDeneyimleri": [
            {
              "unvan": "string veya null",
              "sirket": "string veya null",
              "sehir": "string veya null",
              "baslangic": "Ay Yil formatinda veya null",
              "bitis": "Ay Yil formatinda veya null",
              "halaDevamEdiyor": true/false,
              "aciklama": "string veya null",
              "sektor": "string veya null"
            }
          ],
          "egitimler": [
            {
              "okul": "string veya null",
              "bolum": "string veya null",
              "derece": "Lise/Lisans/Yuksek Lisans/Doktora veya null",
              "baslangic": "string veya null",
              "bitis": "string veya null",
              "not": "string veya null"
            }
          ],
          "yetenekler": ["string listesi"],
          "diller": [
            {
              "ad": "string veya null",
              "seviye": "A1-C2 veya Anadil/Ileri/Orta/Baslangic"
            }
          ],
          "sertifikalar": [
            {
              "ad": "string veya null",
              "kurum": "string veya null",
              "tarih": "string veya null"
            }
          ],
          "projeler": [
            {
              "ad": "string veya null",
              "aciklama": "string veya null",
              "teknolojiler": "string veya null",
              "tarih": "string veya null"
            }
          ],
          "hobiler": ["string listesi"]
        }

        Kurallar:
        - Bulamadigin alanlari null birak, uydurma.
        - Sadece JSON dondur, markdown veya aciklama ekleme.
        """

        let govde: [String: Any] = [
            "model": "gpt-4o",
            "max_tokens": 3000,
            "temperature": 0.1,
            "response_format": ["type": "json_object"],
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": "CV metni:\n\n\(metin)"]
            ]
        ]

        istek.httpBody = try JSONSerialization.data(withJSONObject: govde)
        let (veri, yanit) = try await URLSession.shared.data(for: istek)

        guard let http = yanit as? HTTPURLResponse, http.statusCode == 200 else {
            let mesaj = String(data: veri, encoding: .utf8) ?? "Bilinmeyen hata"
            throw CVOkuyucuHata.apiBaglantisi(mesaj)
        }

        guard let json = try? JSONSerialization.jsonObject(with: veri) as? [String: Any],
              let secimler = json["choices"] as? [[String: Any]],
              let ilkSecim = secimler.first,
              let mesaj = ilkSecim["message"] as? [String: Any],
              let icerik = mesaj["content"] as? String,
              let icerikVeri = icerik.data(using: .utf8) else {
            throw CVOkuyucuHata.parseHatasi
        }

        do {
            return try JSONDecoder().decode(CVParseEdilmis.self, from: icerikVeri)
        } catch {
            throw CVOkuyucuHata.parseHatasi
        }
    }

    // MARK: CVParseEdilmis -> OzgecmisDraft
    func ozgecmisDraftOlustur(from cv: CVParseEdilmis) -> OzgecmisDraft {
        var draft = OzgecmisDraft()

        // Kisisel
        draft.kisisel.adSoyad = cv.adSoyad ?? ""
        draft.kisisel.email = cv.email ?? ""
        draft.kisisel.telefon = cv.telefon ?? ""
        draft.kisisel.sehirIlce = cv.sehir ?? ""
        draft.kisisel.linkedIn = cv.linkedIn ?? ""
        draft.kisisel.webSitesi = cv.webSitesi ?? ""
        draft.kisisel.dogumTarihi = cv.dogumYili ?? ""

        // Ozet
        draft.ozet = cv.ozet ?? ""

        // Is deneyimleri
        draft.isDeneyimleri = (cv.isDeneyimleri ?? []).map { d in
            var deneyim = OzgecmisDeneyim()
            deneyim.unvan = d.unvan ?? ""
            deneyim.sirket = d.sirket ?? ""
            deneyim.sehirIlce = d.sehir ?? ""
            deneyim.baslangic = d.baslangic ?? ""
            deneyim.bitis = d.bitis ?? ""
            deneyim.halaDevamEdiyor = d.halaDevamEdiyor ?? false
            deneyim.aciklama = d.aciklama ?? ""
            deneyim.firmaSektoru = d.sektor ?? ""
            return deneyim
        }

        // Egitimler
        draft.egitimler = (cv.egitimler ?? []).map { e in
            var egitim = OzgecmisEgitim()
            egitim.okul = e.okul ?? ""
            egitim.bolum = e.bolum ?? ""
            egitim.derece = e.derece ?? ""
            egitim.baslangic = e.baslangic ?? ""
            egitim.bitis = e.bitis ?? ""
            egitim.diplomaNotu = e.not ?? ""
            return egitim
        }

        // Yetenekler
        draft.yetenekler = cv.yetenekler ?? []

        // Diller
        draft.diller = (cv.diller ?? []).map { d in
            var dil = OzgecmisDil()
            dil.dilAdi = d.ad ?? ""
            dil.seviye = d.seviye ?? ""
            return dil
        }

        // Sertifikalar
        draft.sertifikalar = (cv.sertifikalar ?? []).map { s in
            var sert = OzgecmisSertifika()
            sert.ad = s.ad ?? ""
            sert.verenKurum = s.kurum ?? ""
            sert.tarih = s.tarih ?? ""
            return sert
        }

        // Projeler
        draft.projeler = (cv.projeler ?? []).map { p in
            var proje = OzgecmisProje()
            proje.projeAdi = p.ad ?? ""
            proje.aciklama = p.aciklama ?? ""
            proje.tarih = p.tarih ?? ""
            proje.link = p.teknolojiler ?? ""
            return proje
        }

        // Hobiler
        draft.hobiler = cv.hobiler ?? []

        return draft
    }
}

// MARK: - OpenAIService uzantisi (API key erisimi icin)
extension OpenAIService {
    var apiKeyPublic: String { apiKey }
}

// MARK: - Ana UI View
struct CVOkuyucuView: View {
    @EnvironmentObject var appTheme: AppTheme
    @Binding var taslak: OzgecmisDraft
    @Environment(\.dismiss) private var dismiss

    @StateObject private var servis = CVOkuyucuService()
    @State private var dosyaSeciciGoster = false
    @State private var didAutoFill = false

    var body: some View {
        NavigationStack {
            ZStack {
                appTheme.backgroundMain.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        bilgiKarti
                            .padding(.top, 8)

                        switch servis.durum {
                        case .bekliyor:
                            yukleButonu
                        case .yukleniyor:
                            yukleniyor
                        case .tamamlandi:
                        if let sonuc = servis.sonuc {
                            // CV parse tamamlandı -> ekstra onay beklemeden formu otomatik doldur.
                            // Sheet'i kapanınca kullanıcı geri döner ve alanlar doldurulmuş halde görünür.
                            if !didAutoFill {
                                Color.clear
                                    .onAppear {
                                        didAutoFill = true
                                        taslak = servis.ozgecmisDraftOlustur(from: sonuc)
                                        dismiss()
                                    }
                            }
                            onizlemeKarti(sonuc)
                        }
                        case .hata(let mesaj):
                            hataKarti(mesaj)
                            yukleButonu
                        }

                        Color.clear.frame(height: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("CV'den Olustur")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Kapat") { dismiss() }
                        .foregroundColor(appTheme.textSecondary)
                }
            }
            .fileImporter(
                isPresented: $dosyaSeciciGoster,
                allowedContentTypes: [.pdf, .image, .jpeg, .png],
                allowsMultipleSelection: false
            ) { sonuc in
                switch sonuc {
                case .success(let urlList):
                    if let url = urlList.first {
                        let erisim = url.startAccessingSecurityScopedResource()
                        Task {
                            await servis.cvOku(url: url)
                            if erisim { url.stopAccessingSecurityScopedResource() }
                        }
                    }
                case .failure:
                    break
                }
            }
        }
    }

    private var bilgiKarti: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "F7D44C"))
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 4) {
                Text("AI ile Otomatik Doldur")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(appTheme.textPrimary)
                Text("CV'nizi yukleyin. Yapay zeka alanlari otomatik dolduracak. PDF veya fotograf destekleniyor.")
                    .font(.system(size: 12))
                    .foregroundColor(appTheme.textSecondary)
                    .lineSpacing(3)
                HStack(spacing: 5) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 9))
                        .foregroundColor(Color(hex: "10B981"))
                    Text("CV icerigi OpenAI'a gonderilir.")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "10B981"))
                }
                .padding(.top, 2)
            }
        }
        .padding(14)
        .background(Color(hex: "F7D44C").opacity(0.07))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "F7D44C").opacity(0.18), lineWidth: 1))
    }

    private var yukleButonu: some View {
        Button { dosyaSeciciGoster = true } label: {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "3B82F6").opacity(0.10))
                        .frame(width: 80, height: 80)
                    Image(systemName: "arrow.up.doc.fill")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundColor(Color(hex: "3B82F6"))
                }
                VStack(spacing: 4) {
                    Text("Dosya Sec")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(appTheme.textPrimary)
                    Text("PDF, JPG veya PNG")
                        .font(.system(size: 13))
                        .foregroundColor(appTheme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 36)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color(hex: "3B82F6").opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
            )
        }
        .buttonStyle(.plain)
    }

    private var yukleniyor: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color(hex: "F7D44C").opacity(0.15), lineWidth: 4)
                    .frame(width: 70, height: 70)
                ProgressView()
                    .tint(Color(hex: "F7D44C"))
                    .scaleEffect(1.5)
            }
            Text(servis.ilerlemeMesaji)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(appTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
    }

    private func onizlemeKarti(_ cv: CVParseEdilmis) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "10B981"))
                Text("CV Analiz Edildi")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: "10B981"))
                Spacer()
                Text(doldurulanAlanSayisi(cv))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(appTheme.textSecondary)
            }
        }
        .padding(16)
        .background(appTheme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(hex: "10B981").opacity(0.25), lineWidth: 1))
    }

    private func doldurulanAlanSayisi(_ cv: CVParseEdilmis) -> String {
        var sayi = 0
        if cv.adSoyad != nil { sayi += 1 }
        if cv.email != nil { sayi += 1 }
        if cv.ozet != nil { sayi += 1 }
        sayi += (cv.isDeneyimleri?.count ?? 0)
        sayi += (cv.egitimler?.count ?? 0)
        return "\(sayi) alan bulundu"
    }

    private var onayButonu: some View {
        Button {
            if let cv = servis.sonuc {
                taslak = servis.ozgecmisDraftOlustur(from: cv)
                dismiss()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                Text("Formu Doldur")
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20).padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(LinearGradient(
                colors: [Color(hex: "10B981"), Color(hex: "059669")],
                startPoint: .leading, endPoint: .trailing))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private func hataKarti(_ mesaj: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "F59E0B"))
            VStack(alignment: .leading, spacing: 3) {
                Text("Bir Sorun Olustu")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: "F59E0B"))
                Text(mesaj)
                    .font(.system(size: 12))
                    .foregroundColor(appTheme.textSecondary)
                    .lineSpacing(3)
            }
        }
        .padding(13)
        .background(Color(hex: "F59E0B").opacity(0.08))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "F59E0B").opacity(0.2), lineWidth: 1))
    }
}

