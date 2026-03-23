import Foundation
import Combine

/// Mevcut iş bilgilerini (kariyer profili) UserDefaults'ta saklamak için Codable taslak.
struct KiyaslamaDraft: Codable {
    var mevcutSirketAdi: String = ""
    var mevcutUnvan: String = ""
    var mevcutUnvanYil: Int = 0
    var mevcutUnvanRank: Int = 1
    var mevcutBrutMaas: Double = 0
    var mevcutMaasSayisi: Int = 12
    var mevcutMaasBrutMu: Bool = true
    var mevcutPrimTutar: Double = 0
    var mevcutPrimBrutMu: Bool = true
    var mevcutGunlukYemekUcreti: Double = 0
    var mevcutAracSegment: String = ""
    var mevcutBesVarMi: Bool = false
    var mevcutBesAylikKatki: String = ""
    var mevcutSigortaTipi: String = "Yok"
    var mevcutSigortaYararlananKisiSayisi: Int = 1
    var mevcutEvInternetTutar: String = ""
    var mevcutFaturaDestegiTutar: String = ""
    var mevcutDilTazminatiTutar: String = ""
    var mevcutCalismaModeli: String = ""
    var mevcutYemekTipi: String = "Yok"
    var mevcutYillikIzin: Int = 14
    var mevcutYolSureDakika: Int = 0
    var mevcutUlasimKalitesi: String = ""
}

/// Kullanıcının "Mevcut İş" (kariyer profili) verilerini cihazda kalıcı saklayan yönetici.
class KariyerProfiliManager: ObservableObject {
    static let shared = KariyerProfiliManager()

    private let key = "KariyerBaseProfile"

    @Published var baseProfile: KiyaslamaDraft?

    init() {
        loadProfile()
    }

    func loadProfile() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let profile = try? JSONDecoder().decode(KiyaslamaDraft.self, from: data) else {
            baseProfile = nil
            return
        }
        baseProfile = profile
    }

    func saveProfile(_ draft: KiyaslamaDraft) {
        baseProfile = draft
        if let data = try? JSONEncoder().encode(draft) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func clearProfile() {
        baseProfile = nil
        UserDefaults.standard.removeObject(forKey: key)
    }

    var hasProfile: Bool {
        baseProfile != nil
    }
}

extension KiyaslamaDraft {
    /// TeklifKiyaslama (veya draft) içindeki mevcut iş alanlarından profil oluşturur.
    static func from(_ source: TeklifKiyaslama) -> KiyaslamaDraft {
        var d = KiyaslamaDraft()
        d.mevcutSirketAdi = source.mevcutSirketAdi
        d.mevcutUnvan = source.mevcutUnvan
        d.mevcutUnvanYil = source.mevcutUnvanYil
        d.mevcutUnvanRank = source.mevcutUnvanRank
        d.mevcutBrutMaas = source.mevcutBrutMaas
        d.mevcutMaasSayisi = source.mevcutMaasSayisi
        d.mevcutMaasBrutMu = source.mevcutMaasBrutMu
        d.mevcutPrimTutar = source.mevcutPrimTutar
        d.mevcutPrimBrutMu = source.mevcutPrimBrutMu
        d.mevcutGunlukYemekUcreti = source.mevcutGunlukYemekUcreti
        d.mevcutAracSegment = source.mevcutAracSegment
        d.mevcutBesVarMi = source.mevcutBesVarMi
        d.mevcutBesAylikKatki = source.mevcutBesAylikKatki
        d.mevcutSigortaTipi = source.mevcutSigortaTipi
        d.mevcutSigortaYararlananKisiSayisi = source.mevcutSigortaYararlananKisiSayisi
        d.mevcutEvInternetTutar = source.mevcutEvInternetTutar
        d.mevcutFaturaDestegiTutar = source.mevcutFaturaDestegiTutar
        d.mevcutDilTazminatiTutar = source.mevcutDilTazminatiTutar
        d.mevcutCalismaModeli = source.mevcutCalismaModeli
        d.mevcutYemekTipi = source.mevcutYemekTipi
        d.mevcutYillikIzin = source.mevcutYillikIzin
        d.mevcutYolSureDakika = source.mevcutYolSureDakika
        d.mevcutUlasimKalitesi = source.mevcutUlasimKalitesi
        return d
    }
}
