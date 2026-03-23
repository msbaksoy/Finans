// ================================================================
// MulakatViewModel.swift
// ================================================================
// Mülakat Simülasyonu — state yönetimi, zamanlayıcı, OpenAI entegrasyonu
// ================================================================

import Foundation
import SwiftUI

@MainActor
final class MulakatViewModel: ObservableObject {

    // MARK: - Giriş ekranı state
    @Published var pozisyon:     String = ""
    @Published var hedefSirket:  String = ""
    @Published var sektor:       String = "Bankacılık & Finans"
    @Published var secilenMod:   MulakatModu = .soruCevap

    // MARK: - Oturum state
    @Published var aktifOturum:  MulakatOturumu? = nil
    @Published var sorular:      [MulakatSoru]  = []
    @Published var mevcutSoruIndex: Int = 0
    @Published var kullaniciYaniti: String = ""

    // MARK: - Akış state
    @Published var asamaState: MulakatAsama = .giris
    @Published var yukleniyor:  Bool = false
    @Published var hata:        String? = nil

    // MARK: - Simülasyon modu: AI konuşma geçmişi
    @Published var konusmaMesajlari: [KonusmaMesaji] = []

    // MARK: - Zamanlayıcı
    @Published var gecenSaniye: Int = 0
    private var timer: Timer? = nil

    // MARK: - Sonuç
    @Published var sonucOturumu: MulakatOturumu? = nil

    // MARK: - Sektörler
    let sektorler = [
        "Bankacılık & Finans",
        "Sigortacılık",
        "Yazılım & Teknoloji",
        "Üretim & Sanayi",
        "Perakende & E-ticaret",
        "Sağlık",
        "Danışmanlık",
        "Kamu & Devlet",
        "Eğitim",
        "Diğer"
    ]

    var mevcutSoru: MulakatSoru? {
        guard mevcutSoruIndex < sorular.count else { return nil }
        return sorular[mevcutSoruIndex]
    }

    var toplamSoru: Int { secilenMod.soruSayisi }
    var ilerleme: Double {
        guard !sorular.isEmpty else { return 0 }
        return Double(mevcutSoruIndex) / Double(sorular.count)
    }
    var bittiMi: Bool { mevcutSoruIndex >= sorular.count && !sorular.isEmpty }

    // MARK: - Oturumu Başlat
    func oturumuBaslat() async {
        guard !pozisyon.trimmingCharacters(in: .whitespaces).isEmpty else {
            hata = "Lütfen pozisyon adı girin."
            return
        }

        // Farklı bir mod seçilip tekrar başlatıldığında
        // önceki oturumu ve soru index'ini tamamen sıfırla.
        sifirla()

        yukleniyor = true
        hata = nil

        let yeniOturum = MulakatOturumu(
            pozisyon: pozisyon,
            hedefSirket: hedefSirket,
            sektor: sektor,
            mod: secilenMod
        )
        aktifOturum = yeniOturum

        // İlk soruyu / senaryoyu üret
        do {
            if secilenMod == .tamSimulasyon {
                // Simülasyon modunda karşılama mesajı
                let karsılama = try await OpenAIService.shared.fetchMulakatKarsilama(
                    pozisyon: pozisyon, sirket: hedefSirket, sektor: sektor
                )
                konusmaMesajlari = [KonusmaMesaji(rol: .ai, icerik: karsılama)]
                asamaState = .simulasyon
            } else {
                // Tüm soruları batch olarak üret
                let uretilen = try await OpenAIService.shared.fetchMulakatSorulari(
                    pozisyon: pozisyon,
                    sirket: hedefSirket,
                    sektor: sektor,
                    mod: secilenMod,
                    adet: secilenMod.soruSayisi
                )
                sorular = uretilen
                asamaState = .sorular
            }
            zamanlayiciBaslat()
        } catch {
            hata = "Sorular yüklenirken hata oluştu. İnternet bağlantını kontrol et."
        }

        yukleniyor = false
    }

    // MARK: - Yanıtı Değerlendir ve Sonraki Soruya Geç
    func yanitVeDevam() async {
        guard mevcutSoruIndex < sorular.count else { return }
        guard !kullaniciYaniti.trimmingCharacters(in: .whitespaces).isEmpty else {
            hata = "Lütfen bir cevap yaz."
            return
        }

        yukleniyor = true
        hata = nil

        // Yanıtı kaydet
        sorular[mevcutSoruIndex].kullaniciYaniti = kullaniciYaniti

        // AI değerlendirmesi
        do {
            let degerlendirme = try await OpenAIService.shared.fetchYanitDegerlendirme(
                soru: sorular[mevcutSoruIndex].soru,
                yanit: kullaniciYaniti,
                mod: secilenMod,
                pozisyon: pozisyon,
                kategori: sorular[mevcutSoruIndex].kategori
            )
            sorular[mevcutSoruIndex].aiPuani   = degerlendirme.puan
            sorular[mevcutSoruIndex].aiYorum   = degerlendirme.yorum
            sorular[mevcutSoruIndex].aiOneri   = degerlendirme.oneri
            if secilenMod == .senaryo {
                sorular[mevcutSoruIndex].starAnaliz = degerlendirme.starAnaliz
            }
        } catch {
            sorular[mevcutSoruIndex].aiPuani = nil
            sorular[mevcutSoruIndex].aiYorum = "Değerlendirme alınamadı."
        }

        kullaniciYaniti = ""
        mevcutSoruIndex += 1
        yukleniyor = false

        // Tüm sorular bittiyse sonuç ekranı
        if bittiMi {
            await sonuclariUret()
        }
    }

    // MARK: - Simülasyon Modu: Kullanıcı Mesajı Gönder
    func simulasyonMesajiGonder() async {
        let mesaj = kullaniciYaniti.trimmingCharacters(in: .whitespaces)
        guard !mesaj.isEmpty else { return }

        konusmaMesajlari.append(KonusmaMesaji(rol: .kullanici, icerik: mesaj))
        kullaniciYaniti = ""
        yukleniyor = true

        do {
            let aiCevap = try await OpenAIService.shared.fetchSimulasyonCevap(
                gecmis: konusmaMesajlari,
                pozisyon: pozisyon,
                sirket: hedefSirket,
                sektor: sektor
            )

            // AI cevabı bitti mi kontrol et
            if aiCevap.contains("[MULAKAT_BITTI]") {
                let temizCevap = aiCevap.replacingOccurrences(of: "[MULAKAT_BITTI]", with: "").trimmingCharacters(in: .whitespaces)
                konusmaMesajlari.append(KonusmaMesaji(rol: .ai, icerik: temizCevap))
                await simulasyonuBitir()
            } else {
                konusmaMesajlari.append(KonusmaMesaji(rol: .ai, icerik: aiCevap))
            }
        } catch {
            konusmaMesajlari.append(KonusmaMesaji(rol: .ai, icerik: "Bağlantı hatası. Lütfen tekrar dene."))
        }

        yukleniyor = false
    }

    // MARK: - Simülasyon Bitiş
    private func simulasyonuBitir() async {
        yukleniyor = true
        do {
            let rapor = try await OpenAIService.shared.fetchSimulasyonRaporu(
                gecmis: konusmaMesajlari,
                pozisyon: pozisyon,
                sirket: hedefSirket,
                sektor: sektor
            )
            aktifOturum?.toplamPuan         = rapor.genelPuan
            aktifOturum?.aiGenelYorum        = rapor.genelYorum
            aktifOturum?.aiGucluYonler       = rapor.gucluYonler
            aktifOturum?.aiGelistirilecek    = rapor.gelistirilecek
            aktifOturum?.tamamlandi          = true
            aktifOturum?.sureDakika          = gecenSaniye / 60
            sonucOturumu                      = aktifOturum
            asamaState                        = .sonuc
        } catch {
            hata = "Rapor oluşturulamadı."
        }
        zamanlayiciDurdur()
        yukleniyor = false
    }

    // MARK: - Final Sonuçları Üret
    func sonuclariUret() async {
        yukleniyor = true
        zamanlayiciDurdur()

        do {
            let finalRapor = try await OpenAIService.shared.fetchFinalRapor(
                sorular: sorular,
                pozisyon: pozisyon,
                sirket: hedefSirket,
                sektor: sektor,
                mod: secilenMod
            )
            aktifOturum?.sorular            = sorular
            aktifOturum?.toplamPuan         = finalRapor.genelPuan
            aktifOturum?.aiGenelYorum        = finalRapor.genelYorum
            aktifOturum?.aiGucluYonler       = finalRapor.gucluYonler
            aktifOturum?.aiGelistirilecek    = finalRapor.gelistirilecek
            aktifOturum?.tamamlandi          = true
            aktifOturum?.sureDakika          = gecenSaniye / 60
            sonucOturumu                      = aktifOturum
            asamaState                        = .sonuc
        } catch {
            // Hata olsa bile sonuç ekranına geç, hesaplanabilenlerle
            aktifOturum?.sorular            = sorular
            aktifOturum?.toplamPuan         = sorular.compactMap { $0.aiPuani }.reduce(0, +) /
                                               max(1, Double(sorular.compactMap { $0.aiPuani }.count))
            aktifOturum?.tamamlandi          = true
            aktifOturum?.sureDakika          = gecenSaniye / 60
            sonucOturumu                      = aktifOturum
            asamaState                        = .sonuc
        }

        yukleniyor = false
    }

    // MARK: - Sıfırla
    func sifirla() {
        zamanlayiciDurdur()
        asamaState       = .giris
        sorular          = []
        mevcutSoruIndex  = 0
        kullaniciYaniti  = ""
        konusmaMesajlari = []
        gecenSaniye      = 0
        aktifOturum      = nil
        sonucOturumu     = nil
        hata             = nil
    }

    // MARK: - Zamanlayıcı
    private func zamanlayiciBaslat() {
        gecenSaniye = 0
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.gecenSaniye += 1
            }
        }
    }

    private func zamanlayiciDurdur() {
        timer?.invalidate()
        timer = nil
    }

    var gecenSureMetni: String {
        let dk  = gecenSaniye / 60
        let sn  = gecenSaniye % 60
        return String(format: "%02d:%02d", dk, sn)
    }
}

// MARK: - Mülakat Aşamaları
enum MulakatAsama {
    case giris
    case sorular
    case simulasyon
    case sonuc
}

// MARK: - Konuşma Mesajı (Simülasyon Modu)
struct KonusmaMesaji: Identifiable {
    let id = UUID()
    var rol: MesajRol
    var icerik: String
    var tarih: Date = Date()
}

enum MesajRol {
    case ai
    case kullanici
}

// MARK: - AI Değerlendirme Sonucu
struct YanitDegerlendirme {
    var puan: Double
    var yorum: String
    var oneri: String
    var starAnaliz: STARAnaliz?
}

// MARK: - Final Rapor
struct MulakatFinalRapor {
    var genelPuan: Double
    var genelYorum: String
    var gucluYonler: [String]
    var gelistirilecek: [String]
}
