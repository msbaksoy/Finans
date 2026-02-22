import Foundation

/// CV form verisi — cv.docx formatına uygun
struct CVModel {
    /// Örnek CV — formatı görmek için açılışta doldurulur, sonra düzenlenebilir/silinir
    static var ornek: CVModel {
        CVModel(
            adSoyad: "Eyyüp ERDEM",
            telefon: "0538 290 19 99",
            adres: "İstanbul / Üsküdar",
            dogumTarihi: "07.04.1990",
            uyruk: "Türkiye Cumhuriyeti",
            email: "eyyuperdem_0504@hotmail.com",
            diller: "İngilizce, Arapça",
            ozet: """
            12 yıllık bankacılık kariyerim boyunca özel bankacılık, ticari ve KOBİ segmentlerinde portföy yönettim. Odağım her zaman sürdürülebilir büyüme, risk disiplini ve sistemli performans üretmek oldu.
            Sıfırdan oluşturduğum portföyleri yüksek hacimli yapılara dönüştürdüm; güçlü müşteri ilişkileri ile finansal verimlilik arasında dengeli bir yapı kurdum.
            """,
            yetkinlikler: """
            • Uluslararası Eğitim
            • Yüksek Hacimli İşlem Yönetimi
            • Portföy Büyütme & Risk Disiplini
            • Kurumsal Proje Koordinasyonu
            • Üst Segment Müşteri Yönetimi
            • Finansal Analiz ve Performans Yönetimi
            • Kredi Analizi ve Sürdürülebilir Büyüme
            """,
            sertifikalar: """
            • Sermaye Piyasası Faaliyetleri Düzey 1 Lisansı – SPK
            • Bireysel Emeklilik Aracılığı Lisans Belgesi
            • SEGEM – Sigorta Acenteleri Teknik Personel Eğitimi Sertifikası
            • Bankalar İçin Temel Hukuk Bilgisi Eğitimi (TKKB)
            • Temel Bankacılık Eğitimi Sertifikası (TKBB)
            """,
            egitimler: [
                EgitimGirisi(baslangicYil: "2013", bitisYil: "2018", derece: "Yüksek Lisans", bolum: "Finans Enstitüsü / Uluslararası Bankacılık ve Finans (Tezli)", universite: "İstanbul Ticaret Üniversitesi", sehir: "İstanbul"),
                EgitimGirisi(baslangicYil: "2009", bitisYil: "2013", derece: "Lisans", bolum: "İktisadi ve İdari Bilimler Fakültesi / İşletme", universite: "Gaziantep Üniversitesi", sehir: "Gaziantep")
            ],
            deneyimler: [
                DeneyimGirisi(baslangicAy: "07", baslangicYil: "2023", bitisAy: "", bitisYil: "", devamEdiyor: true, pozisyon: "Perakende / KOBİ Portföy Yöneticisi", sirket: "Türkiye Emlak Katılım Bankası A.Ş.", sehir: "İstanbul-Üsküdar", gorevler: "Perakende ve KOBİ segmentinde fon ve kredi portföy yönetimi\nPerformans odaklı portföy büyütme ve müşteri derinleştirme\nEmlak Konut GYO projelerinde finansman süreçlerini yöneterek 1,4 milyar TL'nin üzerinde işlem hacmine katkı\nProje bazlı finansman süreçlerinde çok paydaşlı koordinasyon\nRisk analizi, kredi tahsis süreci takibi ve proje bazlı finansman yapılandırmaları"),
                DeneyimGirisi(baslangicAy: "02", baslangicYil: "2023", bitisAy: "07", bitisYil: "2023", devamEdiyor: false, pozisyon: "KOBİ / Ticari Portföy Yöneticisi", sirket: "Türkiye Finans Katılım Bankası A.Ş.", sehir: "İstanbul-Şişli", gorevler: "KOBİ / Ticari segmentlerde portföy büyütme ve yeni müşteri kazanımı\nKredi risk hacmi ve fon büyüklüğünde yüksek oranlı artış\nSegment bazlı performans sıralamasında derece elde edilmesi\nTahsis, risk izleme ve yapılandırma süreçlerinde aktif görev"),
                DeneyimGirisi(baslangicAy: "09", baslangicYil: "2021", bitisAy: "02", bitisYil: "2023", devamEdiyor: false, pozisyon: "Akademik & Operasyonel Gelişim ve Girişimcilik", sirket: "New York", sehir: "ABD", gorevler: "İngilizce dil gelişimim ve akademik hedeflerim doğrultusunda ABD'de bulundum. Amazon'da satış yapan bir firmanın satış ve pazarlama operasyonlarını yönettim.\nVeri temelli satış performans yönetimi ve ölçüm mekanizmaları oluşturulması\nSüreç optimizasyonu ve operasyonel verimlilik artırımı\nSistematik büyüme stratejilerinin kurgulanması ve uygulanması\nÖlçülebilir ve sürdürülebilir performans odaklı süreç tasarımı"),
                DeneyimGirisi(baslangicAy: "06", baslangicYil: "2018", bitisAy: "09", bitisYil: "2021", devamEdiyor: false, pozisyon: "Özel Bankacılık Portföy Yöneticisi", sirket: "Albaraka Türk Katılım Bankası A.Ş.", sehir: "İstanbul-Beyoğlu", gorevler: "Şubenin ilk özel bankacılık portföyünün sıfırdan yapılandırılması\nPortföy büyüklüğünün 50 milyon USD'nin üzerine çıkarılması\nİki yıl üst üste banka genelinde performans birinciliği\nYüksek varlıklı müşteri segmentinde yatırım, finansman ve varlık yönetimi süreçleri"),
                DeneyimGirisi(baslangicAy: "01", baslangicYil: "2014", bitisAy: "06", bitisYil: "2018", devamEdiyor: false, pozisyon: "Operasyon & Bireysel Bankacılık", sirket: "Albaraka Türk Katılım Bankası A.Ş.", sehir: "İstanbul-Fatih", gorevler: "Şube operasyon süreçlerinin etkin ve hatasız yürütülmesi\nYüksek hacimli nakit, kambiyo ve finansman işlemlerinin yönetimi\nOperasyonel risklerin minimize edilmesi ve süreç disiplininin sağlanması\nMüşteri işlem akışlarında koordinasyon ve çözüm odaklı süreç yönetimi\nBireysel bankacılık segmentinde portföy yönetimi ve satış faaliyetleri")
            ]
        )
    }
    
    // Profil fotoğrafı (JPEG/PNG data)
    var fotografData: Data?
    
    // Kişisel Bilgiler
    var adSoyad: String = ""
    var telefon: String = ""
    var adres: String = ""
    var dogumTarihi: String = ""
    var uyruk: String = "Türkiye Cumhuriyeti"
    var email: String = ""
    
    // Diller (virgülle ayrılmış)
    var diller: String = ""
    
    // Özet
    var ozet: String = ""
    
    // Yetkinlikler (her satır bir madde)
    var yetkinlikler: String = ""
    
    // Sertifikalar (her satır bir madde)
    var sertifikalar: String = ""
    
    // Eğitimler
    var egitimler: [EgitimGirisi] = []
    
    // Deneyimler
    var deneyimler: [DeneyimGirisi] = []
}

struct EgitimGirisi: Identifiable {
    let id = UUID()
    var baslangicYil: String = ""
    var bitisYil: String = ""
    var derece: String = "Lisans"  // Lisans, Yüksek Lisans, Doktora vb.
    var bolum: String = ""
    var universite: String = ""
    var sehir: String = ""
}

struct DeneyimGirisi: Identifiable {
    let id = UUID()
    var baslangicAy: String = ""
    var baslangicYil: String = ""
    var bitisAy: String = ""
    var bitisYil: String = ""
    var devamEdiyor: Bool = false
    var pozisyon: String = ""
    var sirket: String = ""
    var sehir: String = ""
    var gorevler: String = ""  // Her satır bir madde
}
