import SwiftUI

// MARK: - Supabase Yapılandırması
// ⚠️ Bu değerleri xcconfig'e taşı, kaynak kodda bırakma
private let supabaseURL  = "https://PROJE_ID.supabase.co"
private let supabaseKey  = "ANON_PUBLIC_KEY"

// MARK: - Model
struct MaasPaylasimi: Codable, Identifiable {
    let id: String?
    let olusturmaTarihi: String?
    let pozisyon: String
    let sektor: String
    let sehir: String
    let deneyimYil: Int
    let brutMaas: Int
    let netMaas: Int
    let sirketBoyutu: String?
    let calismaModelis: String?

    enum CodingKeys: String, CodingKey {
        case id, pozisyon, sektor, sehir
        case olusturmaTarihi  = "olusturma_tarihi"
        case deneyimYil       = "deneyim_yil"
        case brutMaas         = "brut_maas"
        case netMaas          = "net_maas"
        case sirketBoyutu     = "sirket_boyutu"
        case calismaModelis   = "calisma_modeli"
    }
}

struct SektorOrtalama: Identifiable {
    let id = UUID()
    let sektor: String
    let ortalamaBrut: Double
    let kayitSayisi: Int
}

// MARK: - Service
@MainActor
final class MaasVeriService: ObservableObject {
    @Published var sektorOrtalamalar: [SektorOrtalama] = []
    @Published var benzerPozisyonlar: [MaasPaylasimi] = []
    @Published var yukleniyor = false
    @Published var gonderildi = false
    @Published var hata: String? = nil

    // MARK: Veri Gönder
    func gonder(_ paylasim: MaasPaylasimi) async {
        yukleniyor = true
        hata = nil
        do {
            guard let url = URL(string: "\(supabaseURL)/rest/v1/maas_verileri") else { return }
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue("return=minimal",   forHTTPHeaderField: "Prefer")
            req.setValue(supabaseKey,         forHTTPHeaderField: "apikey")
            req.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
            req.httpBody = try JSONEncoder().encode(paylasim)
            let (_, response) = try await URLSession.shared.data(for: req)
            if let http = response as? HTTPURLResponse, http.statusCode == 201 {
                gonderildi = true
                await ortalamalariCek(sektor: paylasim.sektor, pozisyon: paylasim.pozisyon)
            } else {
                hata = "Gönderilemedi. İnternet bağlantını kontrol et."
            }
        } catch {
            hata = "Bağlantı hatası."
        }
        yukleniyor = false
    }

    // MARK: Sektör Ortalamaları
    func ortalamalariCek(sektor: String, pozisyon: String) async {
        guard let url = URL(string:
            "\(supabaseURL)/rest/v1/maas_verileri?sektor=eq.\(sektor.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? sektor)&select=brut_maas,pozisyon"
        ) else { return }
        var req = URLRequest(url: url)
        req.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            struct Ham: Codable {
                let brutMaas: Int
                let pozisyon: String
                enum CodingKeys: String, CodingKey { case brutMaas = "brut_maas"; case pozisyon }
            }
            let liste = try JSONDecoder().decode([Ham].self, from: data)
            // Pozisyona göre grupla
            var gruplar: [String: [Int]] = [:]
            for h in liste { gruplar[h.pozisyon, default: []].append(h.brutMaas) }
            sektorOrtalamalar = gruplar.map { k, v in
                SektorOrtalama(
                    sektor: k,
                    ortalamaBrut: Double(v.reduce(0,+)) / Double(v.count),
                    kayitSayisi: v.count
                )
            }.sorted { $0.kayitSayisi > $1.kayitSayisi }
        } catch { }
    }
}

// MARK: - Ana View
struct AnonymMaasPaylasimiView: View {
    @EnvironmentObject var appTheme: AppTheme
    @Environment(\.dismiss) private var dismiss
    @StateObject private var service = MaasVeriService()

    // Giriş alanları
    @State private var pozisyon   = ""
    @State private var sektor     = "Bankacılık & Finans"
    @State private var sehir      = "İstanbul"
    @State private var deneyimYil = 3
    @State private var brutMaasStr = ""
    @State private var netMaasStr  = ""
    @State private var sirketBoyutu = "Büyük (500+)"
    @State private var calismaModeli = "Ofis"
    @State private var gorundu = false

    private var brutMaas: Int { Int(brutMaasStr.filter { $0.isNumber }) ?? 0 }
    private var netMaas:  Int { Int(netMaasStr.filter  { $0.isNumber }) ?? 0 }
    private var gonderilebilir: Bool { !pozisyon.isEmpty && brutMaas > 0 && netMaas > 0 }

    let sektorler = ["Bankacılık & Finans","Sigortacılık","Yazılım & Teknoloji",
                     "Üretim & Sanayi","Perakende","Sağlık","Danışmanlık","Kamu","Eğitim","Diğer"]
    let sehirler  = ["İstanbul","Ankara","İzmir","Bursa","Antalya","Kocaeli","Adana","Diğer"]
    let boyutlar  = ["Startup (1-50)","Orta (51-500)","Büyük (500+)","Kamu"]
    let modeller  = ["Ofis","Hibrit","Uzaktan (Remote)"]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                appTheme.backgroundMain.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        if service.gonderildi {
                            tesekkurEkrani
                        } else {
                            formEkrani
                        }
                        Color.clear.frame(height: 100)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                }

                if !service.gonderildi {
                    gonderButonu
                }
            }
            .navigationTitle("Maaşını Paylaş")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Kapat") { dismiss() }
                        .foregroundColor(appTheme.textSecondary)
                }
            }
            .alert("Hata", isPresented: Binding(
                get: { service.hata != nil },
                set: { if !$0 { service.hata = nil } }
            )) {
                Button("Tamam") { service.hata = nil }
            } message: {
                Text(service.hata ?? "")
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation { gorundu = true }
                }
            }
        }
    }

    // MARK: Form
    private var formEkrani: some View {
        VStack(spacing: 20) {
            // Gizlilik notu
            gizlilikNotu
                .opacity(gorundu ? 1 : 0)
                .animation(.spring(response: 0.5).delay(0.05), value: gorundu)

            // Pozisyon bilgileri
            formGrubu("Pozisyon Bilgileri", ikon: "briefcase.fill", renk: Color(hex: "3B82F6")) {
                VStack(spacing: 12) {
                    alanSatiri("Pozisyon Adı", placeholder: "Yazılım Geliştirici, Finansal Analist...", text: $pozisyon)
                    pickerSatiri("Sektör", secim: $sektor, secenekler: sektorler)
                    pickerSatiri("Şehir", secim: $sehir, secenekler: sehirler)
                    stepperSatiri("Deneyim Yılı", deger: $deneyimYil, aralik: 0...40)
                    pickerSatiri("Şirket Büyüklüğü", secim: $sirketBoyutu, secenekler: boyutlar)
                    pickerSatiri("Çalışma Modeli", secim: $calismaModeli, secenekler: modeller)
                }
            }
            .opacity(gorundu ? 1 : 0)
            .animation(.spring(response: 0.5).delay(0.10), value: gorundu)

            // Maaş bilgileri
            formGrubu("Maaş Bilgileri", ikon: "turkishlirasign.circle.fill", renk: Color(hex: "10B981")) {
                VStack(spacing: 12) {
                    alanSatiri("Aylık Brüt Maaş (₺)", placeholder: "0", text: $brutMaasStr)
                        .keyboardType(.numberPad)
                    alanSatiri("Aylık Net Maaş (₺)", placeholder: "0", text: $netMaasStr)
                        .keyboardType(.numberPad)
                }
            }
            .opacity(gorundu ? 1 : 0)
            .animation(.spring(response: 0.5).delay(0.16), value: gorundu)
        }
    }

    // MARK: Teşekkür / Sonuç
    private var tesekkurEkrani: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color(hex: "10B981").opacity(0.12))
                    .frame(width: 100, height: 100)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(Color(hex: "10B981"))
            }
            .padding(.top, 20)

            Text("Teşekkürler! 🎉")
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundColor(appTheme.textPrimary)

            Text("Verinle Türkiye'deki çalışanların piyasa değerini öğrenmesine yardım ettin.")
                .font(.system(size: 15))
                .foregroundColor(appTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            if !service.sektorOrtalamalar.isEmpty {
                sektorOrtalamalari
            }
        }
    }

    private var sektorOrtalamalari: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sektöründeki Diğer Pozisyonlar")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(appTheme.textPrimary)

            VStack(spacing: 0) {
                ForEach(service.sektorOrtalamalar.prefix(6)) { ort in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(ort.sektor)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(appTheme.textPrimary)
                            Text("\(ort.kayitSayisi) kayıt")
                                .font(.system(size: 11))
                                .foregroundColor(appTheme.textSecondary)
                        }
                        Spacer()
                        Text(formatTLKisaMaasPaylas(ort.ortalamaBrut))
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundColor(Color(hex: "F7D44C"))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)

                    if ort.id != service.sektorOrtalamalar.prefix(6).last?.id {
                        Divider().padding(.leading, 14)
                    }
                }
            }
            .background(appTheme.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16)
                .stroke(appTheme.cardStroke.opacity(0.3), lineWidth: 1))
        }
    }

    // MARK: Gizlilik Notu
    private var gizlilikNotu: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "10B981"))
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 3) {
                Text("100% Anonim")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "10B981"))
                Text("Kişisel bilgi toplanmaz. İsim, e-posta, telefon istenmez. Sadece pozisyon, sektör ve maaş verisi paylaşılır.")
                    .font(.system(size: 11))
                    .foregroundColor(appTheme.textSecondary)
                    .lineSpacing(3)
            }
        }
        .padding(13)
        .background(Color(hex: "10B981").opacity(0.07))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14)
            .stroke(Color(hex: "10B981").opacity(0.2), lineWidth: 1))
    }

    // MARK: Gönder Butonu
    private var gonderButonu: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [appTheme.backgroundMain.opacity(0), appTheme.backgroundMain],
                startPoint: .top, endPoint: .bottom)
            .frame(height: 24)
            .allowsHitTesting(false)

            Button {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil, from: nil, for: nil
                )
                Task {
                    await service.gonder(MaasPaylasimi(
                        id: nil,
                        olusturmaTarihi: nil,
                        pozisyon: pozisyon,
                        sektor: sektor,
                        sehir: sehir,
                        deneyimYil: deneyimYil,
                        brutMaas: brutMaas,
                        netMaas: netMaas,
                        sirketBoyutu: sirketBoyutu,
                        calismaModelis: calismaModeli
                    ))
                }
            } label: {
                HStack(spacing: 10) {
                    if service.yukleniyor {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.9)
                        Text("Gönderiliyor…")
                            .font(.system(size: 15, weight: .bold))
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 18, weight: .bold))
                        Text("Verileri Paylaş")
                            .font(.system(size: 15, weight: .bold))
                        Spacer()
                        Text("Anonim · Güvenli")
                            .font(.system(size: 11))
                            .opacity(0.65)
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(gonderilebilir && !service.yukleniyor
                    ? LinearGradient(colors: [Color(hex: "065F46"), Color(hex: "047857")],
                                     startPoint: .leading, endPoint: .trailing)
                    : LinearGradient(colors: [Color.gray, Color.gray.opacity(0.8)],
                                     startPoint: .leading, endPoint: .trailing))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color(hex: "065F46").opacity(gonderilebilir ? 0.4 : 0),
                        radius: 12, y: 5)
            }
            .disabled(!gonderilebilir || service.yukleniyor)
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
            .background(appTheme.backgroundMain)
        }
    }

    // MARK: Form Yardımcıları
    @ViewBuilder
    private func formGrubu<Content: View>(
        _ baslik: String,
        ikon: String,
        renk: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 7) {
                Image(systemName: ikon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(renk)
                Text(baslik.uppercased())
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(appTheme.textSecondary)
                    .tracking(1.4)
            }
            content()
        }
        .padding(16)
        .background(appTheme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18)
            .stroke(appTheme.cardStroke.opacity(0.35), lineWidth: 1))
    }

    private func alanSatiri(_ label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(appTheme.textSecondary)
            TextField(placeholder, text: text)
                .font(.system(size: 15))
                .foregroundColor(appTheme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .background(appTheme.formInputBackground.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 11))
                .overlay(RoundedRectangle(cornerRadius: 11)
                    .stroke(appTheme.cardStroke.opacity(0.4), lineWidth: 1))
        }
    }

    private func pickerSatiri(_ label: String, secim: Binding<String>, secenekler: [String]) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(appTheme.textSecondary)
            Spacer()
            Picker("", selection: secim) {
                ForEach(secenekler, id: \.self) { Text($0).tag($0) }
            }
            .pickerStyle(.menu)
            .tint(Color(hex: "3B82F6"))
        }
    }

    private func stepperSatiri(_ label: String, deger: Binding<Int>, aralik: ClosedRange<Int>) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(appTheme.textSecondary)
            Spacer()
            Stepper("\(deger.wrappedValue) yıl", value: deger, in: aralik)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(appTheme.textPrimary)
        }
    }
}

// Yerel kısa TL formatı; isim çakışmasını önlemek için farklı ad
private func formatTLKisaMaasPaylas(_ d: Double) -> String {
    if d >= 1_000_000 { return String(format: "%.1fM₺", d / 1_000_000) }
    if d >= 1_000     { return String(format: "%.0fK₺", d / 1_000) }
    return String(format: "%.0f₺", d)
}

