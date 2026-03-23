import SwiftUI

// MARK: - TÜİK Veri Modeli
struct TufeVeri: Identifiable {
    let id = UUID()
    let yil: Int
    let ay: Int     // 1-12
    let aylikOran: Double   // Aylık % değişim
    let yillikOran: Double  // Yıllık % değişim (YoY)

    var ayAdi: String { RealMaasKaybiView.ayAdlari[ay - 1] }
    var etiket: String { "\(String(yil).suffix(2))'\(ayAdi.prefix(3))" }
}

// MARK: - Ana View
struct RealMaasKaybiView: View {
    @EnvironmentObject var appTheme: AppTheme
    @FocusState private var isInputActive: Bool

    static let ayAdlari = ["Ocak","Şubat","Mart","Nisan","Mayıs","Haziran",
                            "Temmuz","Ağustos","Eylül","Ekim","Kasım","Aralık"]

    // MARK: - TÜİK Resmi Verileri (Kaynak: TÜİK / KPMG Vergi)
    static let tufeVerileri: [TufeVeri] = [
        // 2021
        TufeVeri(yil:2021,ay:1,  aylikOran:1.68,  yillikOran:14.97),
        TufeVeri(yil:2021,ay:2,  aylikOran:0.91,  yillikOran:15.61),
        TufeVeri(yil:2021,ay:3,  aylikOran:1.08,  yillikOran:16.19),
        TufeVeri(yil:2021,ay:4,  aylikOran:1.68,  yillikOran:17.14),
        TufeVeri(yil:2021,ay:5,  aylikOran:1.92,  yillikOran:16.59),
        TufeVeri(yil:2021,ay:6,  aylikOran:1.94,  yillikOran:17.53),
        TufeVeri(yil:2021,ay:7,  aylikOran:1.80,  yillikOran:18.95),
        TufeVeri(yil:2021,ay:8,  aylikOran:1.12,  yillikOran:19.25),
        TufeVeri(yil:2021,ay:9,  aylikOran:1.25,  yillikOran:19.58),
        TufeVeri(yil:2021,ay:10, aylikOran:2.39,  yillikOran:19.89),
        TufeVeri(yil:2021,ay:11, aylikOran:3.51,  yillikOran:21.31),
        TufeVeri(yil:2021,ay:12, aylikOran:13.58, yillikOran:36.08),
        // 2022
        TufeVeri(yil:2022,ay:1,  aylikOran:11.10, yillikOran:48.69),
        TufeVeri(yil:2022,ay:2,  aylikOran:4.81,  yillikOran:54.44),
        TufeVeri(yil:2022,ay:3,  aylikOran:5.46,  yillikOran:61.14),
        TufeVeri(yil:2022,ay:4,  aylikOran:7.25,  yillikOran:69.97),
        TufeVeri(yil:2022,ay:5,  aylikOran:2.98,  yillikOran:73.50),
        TufeVeri(yil:2022,ay:6,  aylikOran:4.95,  yillikOran:78.62),
        TufeVeri(yil:2022,ay:7,  aylikOran:2.37,  yillikOran:79.60),
        TufeVeri(yil:2022,ay:8,  aylikOran:1.46,  yillikOran:80.21),
        TufeVeri(yil:2022,ay:9,  aylikOran:3.08,  yillikOran:83.45),
        TufeVeri(yil:2022,ay:10, aylikOran:3.54,  yillikOran:85.51),
        TufeVeri(yil:2022,ay:11, aylikOran:2.88,  yillikOran:84.39),
        TufeVeri(yil:2022,ay:12, aylikOran:1.18,  yillikOran:64.27),
        // 2023
        TufeVeri(yil:2023,ay:1,  aylikOran:6.65,  yillikOran:57.68),
        TufeVeri(yil:2023,ay:2,  aylikOran:3.15,  yillikOran:55.18),
        TufeVeri(yil:2023,ay:3,  aylikOran:2.29,  yillikOran:50.51),
        TufeVeri(yil:2023,ay:4,  aylikOran:2.39,  yillikOran:43.68),
        TufeVeri(yil:2023,ay:5,  aylikOran:0.04,  yillikOran:39.59),
        TufeVeri(yil:2023,ay:6,  aylikOran:3.92,  yillikOran:38.21),
        TufeVeri(yil:2023,ay:7,  aylikOran:9.49,  yillikOran:47.83),
        TufeVeri(yil:2023,ay:8,  aylikOran:9.09,  yillikOran:58.94),
        TufeVeri(yil:2023,ay:9,  aylikOran:4.75,  yillikOran:61.53),
        TufeVeri(yil:2023,ay:10, aylikOran:3.43,  yillikOran:61.36),
        TufeVeri(yil:2023,ay:11, aylikOran:3.28,  yillikOran:61.98),
        TufeVeri(yil:2023,ay:12, aylikOran:2.93,  yillikOran:64.77),
        // 2024
        TufeVeri(yil:2024,ay:1,  aylikOran:6.70,  yillikOran:64.86),
        TufeVeri(yil:2024,ay:2,  aylikOran:4.53,  yillikOran:67.07),
        TufeVeri(yil:2024,ay:3,  aylikOran:3.16,  yillikOran:68.50),
        TufeVeri(yil:2024,ay:4,  aylikOran:3.18,  yillikOran:69.80),
        TufeVeri(yil:2024,ay:5,  aylikOran:3.37,  yillikOran:75.45),
        TufeVeri(yil:2024,ay:6,  aylikOran:1.64,  yillikOran:71.60),
        TufeVeri(yil:2024,ay:7,  aylikOran:3.23,  yillikOran:61.78),
        TufeVeri(yil:2024,ay:8,  aylikOran:2.47,  yillikOran:51.97),
        TufeVeri(yil:2024,ay:9,  aylikOran:2.97,  yillikOran:49.38),
        TufeVeri(yil:2024,ay:10, aylikOran:2.88,  yillikOran:48.58),
        TufeVeri(yil:2024,ay:11, aylikOran:2.24,  yillikOran:47.09),
        TufeVeri(yil:2024,ay:12, aylikOran:1.03,  yillikOran:44.38),
        // 2025
        TufeVeri(yil:2025,ay:1,  aylikOran:5.03,  yillikOran:42.12),
        TufeVeri(yil:2025,ay:2,  aylikOran:2.27,  yillikOran:39.05),
        TufeVeri(yil:2025,ay:3,  aylikOran:2.46,  yillikOran:38.10),
        TufeVeri(yil:2025,ay:4,  aylikOran:3.00,  yillikOran:37.86),
        TufeVeri(yil:2025,ay:5,  aylikOran:1.53,  yillikOran:35.41),
        TufeVeri(yil:2025,ay:6,  aylikOran:1.37,  yillikOran:35.05),
        TufeVeri(yil:2025,ay:7,  aylikOran:2.06,  yillikOran:33.52),
        TufeVeri(yil:2025,ay:8,  aylikOran:2.04,  yillikOran:32.95),
        TufeVeri(yil:2025,ay:9,  aylikOran:3.23,  yillikOran:33.29),
        TufeVeri(yil:2025,ay:10, aylikOran:2.55,  yillikOran:32.87),
        TufeVeri(yil:2025,ay:11, aylikOran:0.87,  yillikOran:31.07),
        TufeVeri(yil:2025,ay:12, aylikOran:0.89,  yillikOran:30.89),
        // 2026 (mevcut)
        TufeVeri(yil:2026,ay:1,  aylikOran:4.84,  yillikOran:30.65),
        TufeVeri(yil:2026,ay:2,  aylikOran:2.96,  yillikOran:31.53),
    ]

    // MARK: - State
    @State private var eskiMaasStr:   String = ""
    @State private var yeniMaasStr:   String = ""
    @State private var baslangicAy:   Int = 1
    @State private var baslangicYil:  Int = 2024
    @State private var bitisAy:       Int = 12
    @State private var bitisYil:      Int = 2025
    @State private var gorundu = false

    // MARK: - Computed
    private var eskiMaas: Double {
        Double(eskiMaasStr.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: "")) ?? 0
    }
    private var yeniMaas: Double {
        Double(yeniMaasStr.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: "")) ?? 0
    }

    private var mevcutYillar: [Int] {
        Array(Set(Self.tufeVerileri.map { $0.yil })).sorted()
    }

    /// Seçilen dönem arasındaki TÜFE verilerini döndürür
    private var donemVerileri: [TufeVeri] {
        Self.tufeVerileri.filter { v in
            let vToplam = v.yil * 100 + v.ay
            let basToplam = baslangicYil * 100 + baslangicAy
            let bitToplam = bitisYil * 100 + bitisAy
            return vToplam >= basToplam && vToplam <= bitToplam
        }
        .sorted { ($0.yil * 100 + $0.ay) < ($1.yil * 100 + $1.ay) }
    }

    /// Dönem içi birikimli enflasyon (bileşik)
    private var birikimliEnflasyon: Double {
        donemVerileri.reduce(1.0) { acc, v in acc * (1 + v.aylikOran / 100) } - 1
    }

    /// Nominal maaş artışı
    private var nominalArtis: Double {
        guard eskiMaas > 0 else { return 0 }
        return (yeniMaas - eskiMaas) / eskiMaas
    }

    /// Reel maaş değişimi (satın alma gücü)
    private var reelDegisim: Double {
        guard birikimliEnflasyon > -1 else { return 0 }
        return ((1 + nominalArtis) / (1 + birikimliEnflasyon)) - 1
    }

    /// Reel kayıp/kazanım tutarı (eski maaşın satın alma gücüne göre)
    private var reelFarkTL: Double {
        guard eskiMaas > 0 else { return 0 }
        let enflasyonluMaas = eskiMaas * (1 + birikimliEnflasyon)
        return yeniMaas - enflasyonluMaas
    }

    /// Enflasyona eşit kalmak için gereken maaş
    private var gerekenMaas: Double { eskiMaas * (1 + birikimliEnflasyon) }

    private var hesaplandiMi: Bool { eskiMaas > 0 && yeniMaas > 0 && !donemVerileri.isEmpty }
    private var kazandimi: Bool { reelDegisim >= 0 }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                girisKarti
                    .opacity(gorundu ? 1 : 0)
                    .offset(y: gorundu ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.82).delay(0.05), value: gorundu)

                if hesaplandiMi {
                    sonucKarti
                        .opacity(gorundu ? 1 : 0)
                        .animation(.spring(response: 0.5).delay(0.12), value: gorundu)

                    detayKarti
                        .opacity(gorundu ? 1 : 0)
                        .animation(.spring(response: 0.5).delay(0.18), value: gorundu)

                    grafik
                        .opacity(gorundu ? 1 : 0)
                        .animation(.spring(response: 0.5).delay(0.24), value: gorundu)

                    veriNotu
                        .opacity(gorundu ? 1 : 0)
                        .animation(.spring(response: 0.5).delay(0.30), value: gorundu)
                }

                Color.clear.frame(height: 36)
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil, from: nil, for: nil
            )
        }
        .scrollDismissesKeyboard(.interactively)
        .background(appTheme.backgroundMain.ignoresSafeArea())
        .navigationTitle("Reel Maaş Analizi")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            // Varsayılan: bir önceki yıl başından bu yıla
            let yil = Calendar.current.component(.year, from: Date())
            baslangicYil = yil - 1
            baslangicAy  = 1
            bitisYil     = yil
            bitisAy      = min(Calendar.current.component(.month, from: Date()),
                               Self.tufeVerileri.filter { $0.yil == yil }.map { $0.ay }.max() ?? 12)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation { gorundu = true }
            }
        }
    }

    // MARK: - Giriş Kartı
    private var girisKarti: some View {
        VStack(spacing: 18) {
            HStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: "3B82F6"))
                Text("MAAŞ VE DÖNEM BİLGİLERİ")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(appTheme.textSecondary)
                    .tracking(1.5)
                Spacer()
            }

            // Maaşlar
            HStack(spacing: 12) {
                maasAlani(label: "Dönem Başı Maaşın (₺)",
                          placeholder: "Ör: 60.000",
                          text: $eskiMaasStr,
                          renk: Color(hex: "64748B"))
                maasAlani(label: "Dönem Sonu Maaşın (₺)",
                          placeholder: "Ör: 90.000",
                          text: $yeniMaasStr,
                          renk: Color(hex: "3B82F6"))
            }

            // Dönem seçici
            VStack(alignment: .leading, spacing: 10) {
                Text("Karşılaştırma Dönemi")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(appTheme.textSecondary)

                HStack(spacing: 10) {
                    // Başlangıç
                    donemSecici(label: "Başlangıç",
                                ay: $baslangicAy,
                                yil: $baslangicYil)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12))
                        .foregroundColor(appTheme.textSecondary)
                    // Bitiş
                    donemSecici(label: "Bitiş",
                                ay: $bitisAy,
                                yil: $bitisYil)
                }
            }

            // Dönem özeti
            if !donemVerileri.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "3B82F6"))
                    Text("\(donemVerileri.count) aylık veri · \(donemVerileri.first!.etiket) – \(donemVerileri.last!.etiket)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(appTheme.textSecondary)
                    Spacer()
                }
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(Color(hex: "3B82F6").opacity(0.07))
                .cornerRadius(10)
            }
        }
        .padding(18)
        .background(appTheme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(appTheme.cardStroke.opacity(0.35), lineWidth: 1))
        .shadow(color: .black.opacity(appTheme.isLight ? 0.04 : 0), radius: 10, y: 3)
    }

    // MARK: - Sonuç Kartı
    private var sonucKarti: some View {
        let gradyanRenkler: [Color] = kazandimi
            ? [Color(hex: "064E3B"), Color(hex: "065F46")]
            : [Color(hex: "7F1D1D"), Color(hex: "991B1B")]
        let vurguRenk = kazandimi ? Color(hex: "34D399") : Color(hex: "FCA5A5")
        let baslik = kazandimi ? "REEL KAZANIM" : "REEL KAYIP"
        let ikon = kazandimi ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill"

        return ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(LinearGradient(colors: gradyanRenkler,
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
            Circle().fill(Color.white.opacity(0.04)).frame(width: 150)
                .blur(radius: 25).offset(x: 230, y: -45)

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: ikon)
                        .font(.system(size: 14))
                        .foregroundColor(vurguRenk)
                    Text(baslik)
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(1.5)
                }

                // Reel değişim yüzdesi
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(reelDegisim >= 0 ? "+" : "")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundColor(.white.opacity(0.6))
                    Text(String(format: "%.1f%%", reelDegisim * 100))
                        .font(.system(size: 44, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                }

                Text(kazandimi
                     ? "Enflasyonun üzerinde kazandın"
                     : "Maaşın enflasyona yetişemedi")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.75))

                // 3 badge
                HStack(spacing: 10) {
                    statBadge("Nominal", String(format: "+%.1f%%", nominalArtis * 100))
                    statBadge("Enflasyon", String(format: "+%.1f%%", birikimliEnflasyon * 100))
                    statBadge("Fark (₺)", (reelFarkTL >= 0 ? "+" : "") + formatTLKisa(reelFarkTL))
                }
            }
            .padding(20)
        }
        .frame(minHeight: 180)
        .shadow(color: (kazandimi ? Color(hex: "064E3B") : Color(hex: "7F1D1D")).opacity(0.5),
                radius: 18, y: 7)
    }

    // MARK: - Detay Kartı
    private var detayKarti: some View {
        VStack(spacing: 0) {
            detayBaslik("Hesaplama Detayı", "list.bullet.rectangle.fill", Color(hex: "3B82F6"))

            detaySatiri("Dönem Başı Maaş", formatTL(eskiMaas))
            Divider().padding(.leading, 16)
            detaySatiri("Dönem Sonu Maaş", formatTL(yeniMaas))
            Divider().padding(.leading, 16)
            detaySatiri("Nominal Artış", String(format: "+%.2f%%", nominalArtis * 100))
            Divider().padding(.leading, 16)
            detaySatiri("Dönem Birikimli Enflasyon",
                        String(format: "%.2f%%", birikimliEnflasyon * 100),
                        vurgu: true, vurguRenk: Color(hex: "F59E0B"))
            Divider().padding(.leading, 16)
            detaySatiri("Enflasyona Eşit Maaş", formatTL(gerekenMaas),
                        altyazi: "Satın alma gücünü korumak için")
            Divider().padding(.leading, 16)
            detaySatiri("Gerçek Fark",
                        (reelFarkTL >= 0 ? "+" : "") + formatTL(reelFarkTL),
                        vurgu: true,
                        vurguRenk: kazandimi ? Color(hex: "10B981") : Color(hex: "EF4444"))
        }
        .background(appTheme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(appTheme.cardStroke.opacity(0.35), lineWidth: 1))
        .shadow(color: .black.opacity(appTheme.isLight ? 0.04 : 0), radius: 10, y: 3)
    }

    // MARK: - Aylık Enflasyon Grafik (bar chart)
    private var grafik: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "F59E0B"))
                Text("AYLIK ENFLASYON (DÖNEM)")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(appTheme.textSecondary)
                    .tracking(1.5)
                Spacer()
                Text("TÜİK TÜFE")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(appTheme.textSecondary)
            }

            let maxOran = donemVerileri.map { $0.aylikOran }.max() ?? 1
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 5) {
                    ForEach(donemVerileri) { v in
                        let yukseklik = max(4, CGFloat(v.aylikOran / maxOran) * 80)
                        VStack(spacing: 3) {
                            Text(String(format: "%.1f", v.aylikOran))
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(Color(hex: "F59E0B"))
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(LinearGradient(
                                    colors: v.aylikOran > 5
                                        ? [Color(hex: "EF4444"), Color(hex: "F97316")]
                                        : [Color(hex: "F59E0B"), Color(hex: "FCD34D")],
                                    startPoint: .top, endPoint: .bottom))
                                .frame(width: 22, height: yukseklik)
                            Text(v.etiket)
                                .font(.system(size: 7, weight: .medium))
                                .foregroundColor(appTheme.textSecondary)
                                .fixedSize()
                        }
                    }
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 4)
                .padding(.top, 8)
            }
        }
        .padding(16)
        .background(appTheme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(appTheme.cardStroke.opacity(0.35), lineWidth: 1))
        .shadow(color: .black.opacity(appTheme.isLight ? 0.04 : 0), radius: 10, y: 3)
    }

    // MARK: - Veri Notu
    private var veriNotu: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "3B82F6"))
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 3) {
                Text("Veri Kaynağı")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "3B82F6"))
                Text("TÜİK resmi TÜFE (Tüketici Fiyat Endeksi) aylık verileri kullanılmıştır. Kaynak: TÜİK / KPMG Vergi. Son güncelleme: Şubat 2026. Enflasyon bileşik hesaplandı.")
                    .font(.system(size: 11))
                    .foregroundColor(appTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(3)
            }
        }
        .padding(13)
        .background(Color(hex: "3B82F6").opacity(0.07))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14)
            .stroke(Color(hex: "3B82F6").opacity(0.15), lineWidth: 1))
    }

    // MARK: - Yardımcı View'lar
    private func maasAlani(label: String, placeholder: String,
                           text: Binding<String>, renk: Color) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(appTheme.textSecondary)
                .lineLimit(1).minimumScaleFactor(0.8)
            TextField(placeholder, text: text)
                .keyboardType(.numberPad)
                .focused($isInputActive)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(appTheme.textPrimary)
                .onChange(of: text.wrappedValue) { _, newValue in
                    let onlyDigits = newValue.filter { $0.isNumber }
                    if let num = Int(onlyDigits), num > 0 {
                        let formatted = NumberFormatter.localizedString(from: NSNumber(value: num), number: .decimal)
                        if formatted != newValue { text.wrappedValue = formatted }
                    } else if onlyDigits.isEmpty {
                        text.wrappedValue = ""
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, 11)
                .background(appTheme.formInputBackground.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 11))
                .overlay(RoundedRectangle(cornerRadius: 11)
                    .stroke(renk.opacity(0.3), lineWidth: 1.5))
        }
        .frame(maxWidth: .infinity)
    }

    private func donemSecici(label: String, ay: Binding<Int>, yil: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(appTheme.textSecondary)
            VStack(spacing: 4) {
                Picker("", selection: yil) {
                    ForEach(mevcutYillar, id: \.self) { y in
                        Text(String(y)).tag(y)
                    }
                }
                .pickerStyle(.menu)
                .tint(Color(hex: "3B82F6"))
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 8).padding(.vertical, 6)
                .background(appTheme.formInputBackground.opacity(0.5))
                .cornerRadius(10)

                Picker("", selection: ay) {
                    ForEach(1...12, id: \.self) { m in
                        Text(String(Self.ayAdlari[m-1].prefix(3))).tag(m)
                    }
                }
                .pickerStyle(.menu)
                .tint(Color(hex: "3B82F6"))
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 8).padding(.vertical, 6)
                .background(appTheme.formInputBackground.opacity(0.5))
                .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func statBadge(_ baslik: String, _ deger: String) -> some View {
        VStack(spacing: 2) {
            Text(baslik).font(.system(size: 9)).foregroundColor(.white.opacity(0.6))
            Text(deger).font(.system(size: 12, weight: .bold, design: .rounded)).foregroundColor(.white)
        }
        .padding(.horizontal, 10).padding(.vertical, 7)
        .background(Color.white.opacity(0.1)).cornerRadius(8)
    }

    private func detayBaslik(_ metin: String, _ ikon: String, _ renk: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: ikon).font(.system(size: 11, weight: .bold)).foregroundColor(renk)
            Text(metin.uppercased())
                .font(.system(size: 10, weight: .black)).foregroundColor(appTheme.textSecondary).tracking(1.3)
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(appTheme.formInputBackground.opacity(0.4))
    }

    private func detaySatiri(_ baslik: String, _ deger: String,
                              altyazi: String? = nil,
                              vurgu: Bool = false, vurguRenk: Color = .clear) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(baslik).font(.system(size: 13)).foregroundColor(appTheme.textSecondary)
                if let alt = altyazi {
                    Text(alt).font(.system(size: 10)).foregroundColor(appTheme.textSecondary.opacity(0.6))
                }
            }
            Spacer()
            Text(deger)
                .font(.system(size: 13,     weight: vurgu ? .bold : .medium, design: .rounded))
                .foregroundColor(vurgu ? vurguRenk : appTheme.textPrimary)
                .monospacedDigit()
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    private func formatTL(_ d: Double) -> String {
        let f = NumberFormatter(); f.numberStyle = .decimal
        f.locale = Locale(identifier: "tr_TR")
        f.minimumFractionDigits = 0; f.maximumFractionDigits = 0
        return (f.string(from: NSNumber(value: d)) ?? "0") + " ₺"
    }

    private func formatTLKisa(_ d: Double) -> String {
        let abs = Swift.abs(d)
        let prefix = d < 0 ? "-" : ""
        if abs >= 1_000_000 { return "\(prefix)\(String(format: "%.1f", abs/1_000_000))M₺" }
        if abs >= 1_000     { return "\(prefix)\(String(format: "%.0f", abs/1_000))K₺" }
        return "\(prefix)\(String(format: "%.0f", abs))₺"
    }
}

