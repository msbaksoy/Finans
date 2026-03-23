// MARK: - Özgeçmiş Modülü — Bağımsız store (UserDefaults ile sadece bu modülün verisi)

import Foundation
import SwiftUI

private let ozgecmisUserDefaultsKey = "ozgecmis_draft_v1"
private let ozgecmisKayitlarKey = "ozgecmis_kayitli_cvler_v1"

struct KayitliOzgecmis: Codable, Identifiable, Equatable {
    var id: UUID
    var baslik: String
    var olusturulmaTarihi: Date
    var draft: OzgecmisDraft
}

/// Özgeçmiş formunun tek kaynağı. Mevcut CV (CVStore, CVModel) ile entegrasyon yok.
final class OzgecmisStore: ObservableObject {
    @Published var draft: OzgecmisDraft {
        didSet { kaydet() }
    }

    /// En fazla 5 adet kayıtlı özgeçmiş tutulur.
    @Published var kayitliOzgecmisler: [KayitliOzgecmis] = [] {
        didSet { kaydetKayitlar() }
    }

    init(draft: OzgecmisDraft = OzgecmisDraft()) {
        self.draft = draft
        yukle()
        yukleKayitlar()
    }

    private func yukle() {
        guard let data = UserDefaults.standard.data(forKey: ozgecmisUserDefaultsKey),
              let decoded = try? JSONDecoder().decode(OzgecmisDraft.self, from: data) else { return }
        draft = decoded
    }

    private func kaydet() {
        guard let data = try? JSONEncoder().encode(draft) else { return }
        UserDefaults.standard.set(data, forKey: ozgecmisUserDefaultsKey)
    }

    private func yukleKayitlar() {
        guard let data = UserDefaults.standard.data(forKey: ozgecmisKayitlarKey),
              let decoded = try? JSONDecoder().decode([KayitliOzgecmis].self, from: data) else { return }
        kayitliOzgecmisler = decoded
    }

    private func kaydetKayitlar() {
        guard let data = try? JSONEncoder().encode(kayitliOzgecmisler) else { return }
        UserDefaults.standard.set(data, forKey: ozgecmisKayitlarKey)
    }

    /// Taslağı sıfırlar (isteğe bağlı)
    func sifirla() {
        draft = OzgecmisDraft()
    }

    /// Kullanıcı "Kaydet" butonuna bastığında manuel tetiklenebilen kayıt.
    func manuelKaydet() {
        kaydet()
    }

    /// Mevcut taslağı yeni bir kayıtlı CV olarak ekler (en fazla 5 adet tutulur). İsim boşsa otomatik başlık üretilir.
    func kayitliCvEkle(baslik kullaniciBasligi: String? = nil) {
        let baslik = (kullaniciBasligi?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 } ?? olusturKayitBasligi(from: draft)
        let kayit = KayitliOzgecmis(id: UUID(), baslik: baslik, olusturulmaTarihi: Date(), draft: draft)

        var yeniListe = kayitliOzgecmisler
        if yeniListe.count >= 5 {
            yeniListe.removeFirst()
        }
        yeniListe.append(kayit)
        kayitliOzgecmisler = yeniListe
    }

    /// Seçilen kayıtlı CV'yi aktif taslak olarak yükler.
    func kayitYukle(_ kayit: KayitliOzgecmis) {
        draft = kayit.draft
    }

    /// Kayıtlı CV'yi listeden siler.
    func kayitSil(_ kayit: KayitliOzgecmis) {
        kayitliOzgecmisler.removeAll { $0.id == kayit.id }
    }

    private func olusturKayitBasligi(from draft: OzgecmisDraft) -> String {
        let ad = draft.kisisel.adSoyad.trimmingCharacters(in: .whitespacesAndNewlines)
        let unvan = draft.isDeneyimleri.first?.unvan.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let sirket = draft.isDeneyimleri.first?.sirket.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if !ad.isEmpty && (!unvan.isEmpty || !sirket.isEmpty) {
            let isPart = [unvan, sirket].filter { !$0.isEmpty }.joined(separator: " – ")
            return "\(ad) / \(isPart)"
        } else if !ad.isEmpty {
            return ad
        } else if !unvan.isEmpty || !sirket.isEmpty {
            return [unvan, sirket].filter { !$0.isEmpty }.joined(separator: " – ")
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return "CV - \(formatter.string(from: Date()))"
        }
    }
}
