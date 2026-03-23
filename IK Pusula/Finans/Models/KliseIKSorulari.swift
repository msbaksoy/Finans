// ================================================================
// KliseIKSorulari.swift
// ================================================================
// 15 klişe İK sorusu, 5 kategori — gizli anlam, cevap rehberi, yapılmaması gereken
// ================================================================

import Foundation
import SwiftUI

struct KliseSoru: Identifiable {
    let id = UUID()
    let kategori: KliseKategori
    let soru: String
    /// IK'nın gerçekte ne demek istediği — espri katmanı
    let gizliAnlam: String
    /// Gülen yüz tepkisi (0-3 arası 😐😄😂🤣)
    let espriSeviyesi: Int
    /// Gerçekten nasıl cevaplanmalı
    let profesyonelCevap: String
    /// Kaçınılması gereken hata
    let yapilmamasıGereken: String
    /// Bonus ipucu (opsiyonel)
    let bonusIpucu: String?
}

enum KliseKategori: String, CaseIterable {
    case klasik       = "Efsane Klasikler"
    case sahteDerin   = "Sahte Derin Sorular"
    case tuzak        = "Tuzak Sorular"
    case turkiyeOzel  = "Türkiye'ye Özel"
    case motivasyon   = "Motivasyon Tiyatrosu"

    var ikon: String {
        switch self {
        case .klasik:      return "star.fill"
        case .sahteDerin:  return "brain.head.profile"
        case .tuzak:       return "exclamationmark.triangle.fill"
        case .turkiyeOzel: return "flag.fill"
        case .motivasyon:  return "theatermasks.fill"
        }
    }

    var renk: String {
        switch self {
        case .klasik:      return "3B82F6"
        case .sahteDerin:  return "8B5CF6"
        case .tuzak:       return "EF4444"
        case .turkiyeOzel: return "F59E0B"
        case .motivasyon:  return "10B981"
        }
    }
}

// MARK: - Soru Bankası
enum KliseIKSorulari {

    static let tumSorular: [KliseSoru] = klasikler + sahteDerin + tuzaklar + turkiyeOzel + motivasyon

    // MARK: - Efsane Klasikler
    static let klasikler: [KliseSoru] = [

        KliseSoru(
            kategori: .klasik,
            soru: "Bize biraz kendinizden bahseder misiniz?",
            gizliAnlam: "CV'nizi açmadım, açsaydım da okumak için zamanım yoktu. Sizi konuşturayım, ben biraz kafayı toparlayayım.",
            espriSeviyesi: 3,
            profesyonelCevap: "Tuzağa düşme: 'Adım Ahmet, 1990 doğumluyum, futbol severim...' diye başlama. Bunun yerine 60 saniyelik bir kariyer özeti hazırla. Şu an ne yapıyorsun → neden bu pozisyon → ne katacaksın. Sırasıyla anlat, kişisel bilgilerle vakit kaybetme.",
            yapilmamasıGereken: "'Nelerden bahsedeyim acaba?' diye sorup bekleme. IK'nın kafası şimdi daha da karışır.",
            bonusIpucu: "Buna 'elevator pitch' denir. Asansörde 60 saniyede anlat. Yoksa asansör kapanır, fırsat da kapanır."
        ),

        KliseSoru(
            kategori: .klasik,
            soru: "5 yıl sonra kendinizi nerede görüyorsunuz?",
            gizliAnlam: "Aslında merak ettiğimiz tek şey şu: 2 ay sonra daha iyi bir teklifle gidecek misiniz? Bunu sormak ayıp olduğu için bu soruyu sorduk.",
            espriSeviyesi: 2,
            profesyonelCevap: "İdeal cevap şirkete bağlılık sinyali vermeli ama yalancı çıkmamalısın. 'Bu şirkette [pozisyon]'dan [bir üst pozisyon]'a geçmeyi, aynı zamanda [sektöre özgü bir beceri] geliştirmeyi hedefliyorum' şeklinde somut ama esnek bir çerçeve çiz.",
            yapilmamasıGereken: "'Kendi şirketimi kurmuş olmak istiyorum' deme. Doğru olabilir ama IK şu an işe alım formu doldurmak istiyor, yatırımcı değil.",
            bonusIpucu: "Bu soruyu hiçbir IK gerçekten ciddiye almaz. Ama sormaya devam ederler. Evren böyle çalışıyor."
        ),

        KliseSoru(
            kategori: .klasik,
            soru: "Neden bu şirkette çalışmak istiyorsunuz?",
            gizliAnlam: "Şirketimiz hakkında en az 10 dakika araştırma yaptınız mı? Yapmadıysanız şimdi çok belli olacak.",
            espriSeviyesi: 2,
            profesyonelCevap: "Şirketi gerçekten araştır — ne iş yaparlar, son haberleri ne, kültürleri nasıl? Sonra kendi deneyimlerinle bağla. 'Sizi takip ediyorum çünkü [gerçek bir şey]' çok daha güçlü. Jenerik 'büyük ve saygın bir kurum' cevabı verirsen IK içinden 'Google, Apple ve diğer 500 şirkete de aynısını mı söyledin acaba?' diye düşünür.",
            yapilmamasıGereken: "Web sitenizde yazan misyon-vizyonu kelimesi kelimesine okuma. Şirketi onlara anlatmak tuhaf bir his bırakır.",
            bonusIpucu: nil
        ),

        KliseSoru(
            kategori: .klasik,
            soru: "Maaş beklentiniz nedir?",
            gizliAnlam: "Eğer çok düşük söylersen seni o fiyata alırız. Çok yüksek söylersen 'bütçemizin biraz üzerinde' deriz. Bu sorunun doğru cevabı yok, sadece daha az yanlış cevaplar var.",
            espriSeviyesi: 3,
            profesyonelCevap: "Piyasa araştırması yap — Linkedin, kariyer siteleri, sektör raporları. Bir aralık belirle, alt sınırı gerçek hedefin olsun. 'Araştırmama göre bu pozisyon için piyasa ₺X-Y arasında, ben de bu aralıkta düşünüyorum' de. Net bir sayı söylemek, '45-55K arası düşünüyorum' demekten daha güçlü bir konumda bırakır seni.",
            yapilmamasıGereken: "'Size bırakıyorum' deme. Bu 'beni ucuza alın' demektir.",
            bonusIpucu: "KariyerLens'in Kariyer Kıyaslama özelliğini kullan — piyasa değerini gerçek rakamlarla öğren."
        ),

    ]

    // MARK: - Sahte Derin Sorular
    static let sahteDerin: [KliseSoru] = [

        KliseSoru(
            kategori: .sahteDerin,
            soru: "En büyük zayıf yönünüz nedir?",
            gizliAnlam: "Sizi bu soruyla biraz sıkıştıralım, panikleyecek misiniz görelim. Ayrıca 'Çok çalışkanım, bu benim zayıflığım' cevabını kaç kişi verdi diye içimizden bahis tutuyoruz.",
            espriSeviyesi: 3,
            profesyonelCevap: "Gerçek ama 'ölümcül' olmayan bir zayıflık seç. Üstelik nasıl üstüne çalıştığını mutlaka ekle. 'Sunum yaparken gerginim, bu yüzden Toastmasters'a katıldım ve son 6 ayda 8 sunum yaptım' gibi. Zayıflığı zaten çözdüğünü gösteren bir cevap hem dürüst hem güçlü.",
            yapilmamasıGereken: "'Çok mükemmeliyetçiyim' veya 'Bazen çok çok çalışıyorum' deme. Bu cevabı 1990'da icat ettiler ve hâlâ emekliye ayırmadılar, ama sen ayır.",
            bonusIpucu: "IK bu soruyu sorarken aslında öz farkındalığını ölçüyor. Dürüstlük + farkındalık + gelişim = mükemmel cevap."
        ),

        KliseSoru(
            kategori: .sahteDerin,
            soru: "Kendinizi 3 sıfatla tanımlar mısınız?",
            gizliAnlam: "Bu soruyu sormak için MBA yaptık. Cevapların %94'ü 'çalışkan, analitik, ekip oyuncusu' olacak. Ama yine de sormaya devam edeceğiz.",
            espriSeviyesi: 3,
            profesyonelCevap: "Klişelerden kaç: çalışkan, analitik, uyumlu — bunları herkes söylüyor. Pozisyona özgü ve kanıtlanabilir sıfatlar seç. Her sıfatın arkasına kısa bir örnek koy. 'Meraklı — her projede bir şey denemeden bitirmem' gibi. Üç sıfat değil, üç mini hikaye.",
            yapilmamasıGereken: "Sıfatları saymakla bırakma. 'Çalışkan, analitik, ekip oyuncusu' deyip susarsan IK da susar ve garip bir sessizlik olur.",
            bonusIpucu: nil
        ),

        KliseSoru(
            kategori: .sahteDerin,
            soru: "Başarısızlıkla nasıl başa çıkarsınız?",
            gizliAnlam: "Yıkılıp yıkılmadığınızı, ya da 'Ben hiç başarısız olmam' deyip demeyeceğinizi merak ediyoruz. İkincisini diyenler direkt elenir.",
            espriSeviyesi: 2,
            profesyonelCevap: "Gerçek bir başarısızlık örneği ver. Ama şunu net göster: ne öğrendin ve bir sonraki seferde ne değişti? Başarısızlığı inkâr etmek seni 'olgun olmayan aday' kategorisine sokar. Başarısızlıktan öğrenen insan ise şirkete 'ben hatayı tekrarlamam' diyor.",
            yapilmamasıGereken: "'Ben pek başarısız olmam, her şeyi önceden planlarım' deme. Bu cevap IK'yı iki şeye inandırır: ya yalancısın, ya da hiç risk almamışsın.",
            bonusIpucu: "STAR formatı burada çok işe yarar: durum → görev → yanlış eylem → öğrenilen ders."
        ),

        KliseSoru(
            kategori: .sahteDerin,
            soru: "Neden şu anki işinizden ayrılıyorsunuz?",
            gizliAnlam: "Eski şirketinizi kötüler misiniz? Yöneticinizin berbat biri olduğunu mu söylersiniz? Bize biraz dedikodu gelsin.",
            espriSeviyesi: 2,
            profesyonelCevap: "Altın kural: eski şirketi, yöneticini, meslektaşlarını asla kötüleme. Bunun yerine 'neye doğru gittiğini' anlat, 'neden kaçtığını' değil. 'Yeni sorumluluklar almak istiyorum, bu pozisyon tam aradığım gelişim fırsatını sunuyor' gibi. Pozitif çerçeve her zaman kazanır.",
            yapilmamasıGereken: "'Yöneticimle geçinemiyordum' deme — bu cevap IK'ya 'bu kişiyle de geçinemeyebiliriz' dedirtir.",
            bonusIpucu: "Bir mülakat koçunun dediği gibi: 'Ayrılma sebebini her zaman büyüme sebebine çevir.'"
        ),

    ]

    // MARK: - Tuzak Sorular
    static let tuzaklar: [KliseSoru] = [

        KliseSoru(
            kategori: .tuzak,
            soru: "Ekip çalışmasını mı yoksa bağımsız çalışmayı mı tercih edersiniz?",
            gizliAnlam: "Bu sorunun doğru cevabı yok. Ekip dersen 'yalnız çalışamaz' diye not düşeceğiz, bağımsız dersen 'ekiple uyumsuz olabilir' yazacağız. Bunu sadece söylemek istedik.",
            espriSeviyesi: 3,
            profesyonelCevap: "İkisini de yap. Gerçekten. 'Duruma göre her ikisini de yapabiliyorum — analiz ve odak gerektiren işlerde bağımsız çalışmayı, strateji ve yaratıcılık gerektirenlerde ise ekiple çalışmayı tercih ederim' de. Bunu bir örnekle destekle.",
            yapilmamasıGereken: "Sadece birini seç. Bu soruyu soran IK her iki yetkinliği de ölçüyor.",
            bonusIpucu: nil
        ),

        KliseSoru(
            kategori: .tuzak,
            soru: "Bizi rakiplerimizden neden seçtiniz?",
            gizliAnlam: "Rakiplerimize de başvurdunuz mu merak ediyoruz. Cevabınız her halükarda 'evet'tir ama yine de soralım.",
            espriSeviyesi: 2,
            profesyonelCevap: "Bu soruyu araştırma yaparak geç. Şirketin rakiplerine kıyasla gerçek farklılığını bil — ürün, kültür, büyüme. 'Sizi takip ediyorum çünkü [gerçek, spesifik bir şey]' çok güçlü. Ama sakın rakip şirketleri kötüleme; onlar hakkında söylediğin her şey aynada sana bakıyor.",
            yapilmamasıGereken: "'Aslında onlara da başvurdum ama siz daha önce cevap verdiniz' deme. Gerçek olabilir ama bu röportajda bunu söyleme.",
            bonusIpucu: nil
        ),

        KliseSoru(
            kategori: .tuzak,
            soru: "Bize sormak istediğiniz sorular var mı?",
            gizliAnlam: "'Hayır, her şey net' dersen 'bu aday hazırlıksız ve meraklı değil' diye not düşeceğiz. Ama çok soru sorarsan 'bu adam bırakmıyor' diyeceğiz. Ortayı bulmanızı öneririz.",
            espriSeviyesi: 2,
            profesyonelCevap: "2-3 kaliteli soru hazırla. Maaş ve yan haklar için henüz erken (ilk görüşmeyse). Bunun yerine: 'Bu pozisyonda ilk 90 günde başarı nasıl ölçülür?', 'Ekibin en güçlü yönü nedir?', 'Sizi bu şirkette tutan nedir?' gibi sorular hem meraklı hem akıllı görünmeni sağlar.",
            yapilmamasıGereken: "'Hayır, gayet net, teşekkürler' deme ve oturumdan çık. Bu fırsatı israf etme.",
            bonusIpucu: "Son soru olarak 'Bir sonraki adım ne zaman, nasıl ilerliyoruz?' diye sor. Hem proaktif görünürsün hem de ne zaman haber beklediğini bilirsin."
        ),

    ]

    // MARK: - Türkiye'ye Özel
    static let turkiyeOzel: [KliseSoru] = [

        KliseSoru(
            kategori: .turkiyeOzel,
            soru: "Askerlik durumunuz nedir?",
            gizliAnlam: "Sizi işe alsak 2 ay sonra askerliğe gidecek misiniz diye korkuyoruz. Bunu sormak yasal mı değil mi tam bilmiyoruz ama sormaya devam ediyoruz.",
            espriSeviyesi: 3,
            profesyonelCevap: "Türkiye'de bu soru yaygın ama Avrupa İnsan Hakları standartları açısından tartışmalı. İşe alım kararını olumsuz etkileyecekse cevaplamak zorunda değilsin. Cevaplamak istersen: 'Askerlik yükümlülüğümü [tarih] itibarıyla tamamladım / ertelettirdim' şeklinde kısa tut, detaya girme.",
            yapilmamasıGereken: "Konuyu uzatma, savunmaya geçme. Kısa ve net cevap ver, konuyu değiştir.",
            bonusIpucu: "Bu soruyu soran her şirket kötü niyetli değildir — ama bu bilgi işe alım kararını etkilememelidir. Bunu bilmen yeterli."
        ),

        KliseSoru(
            kategori: .turkiyeOzel,
            soru: "Evli misiniz, çocuğunuz var mı?",
            gizliAnlam: "Kadın adaylara daha sık soruluyor bu soru. Aslında 'mesai saatleri dışında da çalışabilir misiniz?' diye sormak istiyoruz ama o kadar açık soramıyoruz.",
            espriSeviyesi: 3,
            profesyonelCevap: "Bu soru yasal açıdan problem; işe alım kararlarını etkileyemez. Cevaplamak zorunda değilsin. Kibarca geçmek istersen: 'Kişisel hayatım iş performansımı etkilemiyor, bu konuda endişeniz olmasın' diyebilirsin. Sormaya devam ederlerse 'Bu sorunun işe alım süreciyle ilgisi nedir?' diye sorabilirsin.",
            yapilmamasıGereken: "Savunmaya geçme veya öfkelenme — sakin ve profesyonel kal. Bu soruyu soran her şirkette kötü iş-yaşam dengesi olduğu anlamına gelmeyebilir.",
            bonusIpucu: "Eğer şirket bu soruya verdiğin cevaba göre karar veriyorsa, bu şirketin kültürü hakkında çok önemli bir ipucu almış oluyorsun."
        ),

        KliseSoru(
            kategori: .turkiyeOzel,
            soru: "Referanslarınız var mı?",
            gizliAnlam: "Eski patronunuzla ilişkiniz ne kadar iyi? Bu mülakat aslında sona erdi, bundan sonrası formalite.",
            espriSeviyesi: 1,
            profesyonelCevap: "Her zaman 2-3 referans hazırla. Eski yöneticiler, mentorunuz veya birlikte proje yaptığınız kıdemli biri ideal. Referans vermeden önce onları mutlaka ara — hem izin al, hem ne söyleyeceklerini bilmelerini sağla. 'Sizi referans olarak verebilir miyim?' sorusu ve 'şu pozisyona başvuruyorum, şu konuları vurgulaman yardımcı olur' bilgisi kritik.",
            yapilmamasıGereken: "'Eski patronumla pek aramız iyi değil ama...' diye başlayıp referans verme. Bu konuşma bitmiştir.",
            bonusIpucu: nil
        ),

        KliseSoru(
            kategori: .turkiyeOzel,
            soru: "Hangi üniversiteden mezunsunuz?",
            gizliAnlam: "Türkiye'de CV'de yazıyor ama yine de sormak hoşumuza gidiyor. Aslında 'bölüm sıralaması kaçtı' diye sormak istiyoruz.",
            espriSeviyesi: 2,
            profesyonelCevap: "Okulu ne olursa olsun savunmaya geçme. Mezun olduğun okuldan gurur duy. Okul adından sonra hemen pratik deneyimlerine, projelerine, sektördeki çalışmalarına geç. 'X Üniversitesi'nden mezun oldum, orada Y projesini yürüttüm' şeklinde köprü kur.",
            yapilmamasıGereken: "Okul adını söyleyip özür diler gibi bir tavır takınma. Bu özgüven sorununu ele veriyor.",
            bonusIpucu: "İşverenler giderek daha çok deneyim ve beceriye bakıyor. Okul tek kriter değil, özellikle birkaç yıl deneyim sonrası."
        ),

    ]

    // MARK: - Motivasyon Tiyatrosu
    static let motivasyon: [KliseSoru] = [

        KliseSoru(
            kategori: .motivasyon,
            soru: "Sizi motive eden nedir?",
            gizliAnlam: "Para demeyeceksiniz, biliyoruz. 'Zorluklar' veya 'büyümek' diyeceksiniz. Bunu içimizden tahmin ediyoruz bile. Sizi şaşırtmayı becerebilecek misiniz?",
            espriSeviyesi: 3,
            profesyonelCevap: "Para ve kariyer gerçek motivasyonlardan. Ama bunları söylemek için çerçeveleme önemli. 'Somut sonuçlar görmek beni motive ediyor — bir projeyi tamamladığımda veya hedefi aştığımda bu bana çok şey ifade ediyor' gibi somut ve dürüst bir cevap, 'insanlara yardım etmek' jargonundan çok daha güçlü.",
            yapilmamasıGereken: "'Değer üretmek, fark yaratmak, dünyayı değiştirmek' gibi cümleler kurma. Bu cevaplar artık LinkedIn'de bile klişe sayılıyor.",
            bonusIpucu: "Gerçekten seni motive eden neyse onu söyle. Özgünlük her zaman kazanır."
        ),

        KliseSoru(
            kategori: .motivasyon,
            soru: "Ekibinize nasıl bir değer katarsınız?",
            gizliAnlam: "Özgüveninizi test ediyoruz. 'Mütevazı olayım' diyip geçiştirirseniz kaybedersiniz, çok abartırsanız da. Dengeyi bulmak için ortalama 2.7 yıl deneyim gerekiyor.",
            espriSeviyesi: 2,
            profesyonelCevap: "Bu soruyu somut örnekle cevapla. 'Genelde [spesifik beceri] konusunda güçlüyüm — örneğin [gerçek bir proje veya sonuç]' şeklinde. 'Takım ruhunu yükseltiyorum' gibi ölçülemez ifadeler yerine ölçülebilir katkılar anlat.",
            yapilmamasıGereken: "'Fazla bir şey katamam, hâlâ öğreniyorum' deme. Mütevazı olmak güzel ama aşırı küçümseme seni seçilemez kılar.",
            bonusIpucu: nil
        ),

        KliseSoru(
            kategori: .motivasyon,
            soru: "Bu pozisyon için neden sizin doğru aday olduğunuzu düşünüyorsunuz?",
            gizliAnlam: "Mülakatın sonu geldi. Bu aslında 'bizi ikna etmek için son şansınız' sorusudur. Ve evet, bu soruyu neden sorduğumuzu biz de tam bilmiyoruz.",
            espriSeviyesi: 2,
            profesyonelCevap: "Bu soru için hazırlıklı gel. Pozisyonun gereksinimlerine bak, kendinle eşleştir. 'Bu pozisyon [X, Y, Z] arıyor. Ben [X konusunda şu proje], [Y konusunda şu deneyim], [Z konusunda şu sonuç] ile bu ihtiyacı karşılayabilirim' formatını kullan. Somut, özgüvenli ve alçakgönüllü.",
            yapilmamasıGereken: "'Bilmiyorum, bunu siz değerlendirin' deme. Bu soruyu soran IK zaten değerlendiriyor — sen de kendi lobini yap.",
            bonusIpucu: "Bu cevabını ezberle. Mülakattan ayrılmadan önce son güçlü izlenimi bırakma fırsatın bu."
        ),

        KliseSoru(
            kategori: .motivasyon,
            soru: "Stres altında nasıl çalışırsınız?",
            gizliAnlam: "Aslında sormak istediğimiz: 'Sizi çok çalıştıracağız, buna hazır mısınız?' Ama bu kadar açık soramayız.",
            espriSeviyesi: 3,
            profesyonelCevap: "Gerçek bir örnek ver. 'Baskılı dönemlerde önceliklendirme yaparım — önce kritik olanı bitiririm, uzun vadeli olanı parçalara bölerim' gibi pratik bir yaklaşım anlat. Ve gerçek bir örnek ekle: 'Geçen yıl [X proje] döneminde böyle bir süreç yaşadım, şöyle yönettim.'",
            yapilmamasıGereken: "'Ben stres altında çok iyi çalışırım, baskı beni güçlendirir' deme. Bu cevap ya yalan ya da geleceğin patronuna 'sizi daha çok bastırın' izni vermek.",
            bonusIpucu: "Stresle başa çıkma yöntemlerinizi somutlaştır: spor, to-do listesi, Pomodoro tekniği gibi. Bunlar sizi organize ve öz-farkındalıklı gösterir."
        ),

    ]

    // MARK: - Günün Sorusu (tarihe göre döner, internet gerekmez)
    static var gunSorusu: KliseSoru {
        let gun = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = (gun - 1) % tumSorular.count
        return tumSorular[index]
    }
}
