import SwiftUI
import UIKit

struct ZamHesaplayiciView: View {
    @EnvironmentObject var appTheme: AppTheme
    @FocusState private var mevcutBrutFocused: Bool
    @FocusState private var zamSonrasiBrutFocused: Bool

    @State private var mevcutBrutStr   = ""
    @State private var zamSonrasiBrut  = ""
    @State private var zamAyi: Int     = 1
    @State private var gorundu         = false

    private var mevcutBrut: Double {
        Double(mevcutBrutStr.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: "")) ?? 0
    }
    private var zamSonrasiBrutVal: Double {
        Double(zamSonrasiBrut.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: "")) ?? 0
    }
    private var zamYuzdesi: Double {
        guard mevcutBrut > 0 else { return 0 }
        return ((zamSonrasiBrutVal - mevcutBrut) / mevcutBrut) * 100
    }
    private var senaryoA: [AylikBrutNetDetay] {
        guard mevcutBrut > 0 else { return [] }
        return BrutNetCalculator.hesaplaYillikDetayli(brutlar: Array(repeating: mevcutBrut, count: 12))
    }
    private var senaryoB: [AylikBrutNetDetay] {
        guard mevcutBrut > 0, zamSonrasiBrutVal > 0 else { return [] }
        var brutlar = Array(repeating: mevcutBrut, count: 12)
        for i in (zamAyi-1)..<12 { brutlar[i] = zamSonrasiBrutVal }
        return BrutNetCalculator.hesaplaYillikDetayli(brutlar: brutlar)
    }
    private var yillikNetA:    Double { senaryoA.reduce(0) { $0 + $1.toplamNetEleGecen } }
    private var yillikNetB:    Double { senaryoB.reduce(0) { $0 + $1.toplamNetEleGecen } }
    private var yillikNetFark: Double { yillikNetB - yillikNetA }
    private var aylikNetMevcut: Double { senaryoA.last?.toplamNetEleGecen ?? 0 }
    private var aylikNetYeni:   Double { senaryoB.last?.toplamNetEleGecen ?? 0 }
    private var aylikNetFark:   Double { aylikNetYeni - aylikNetMevcut }
    private var hesaplandiMi: Bool { mevcutBrut > 0 && zamSonrasiBrutVal > mevcutBrut }
    private let aylar = ["Ocak","Şubat","Mart","Nisan","Mayıs","Haziran",
                         "Temmuz","Ağustos","Eylül","Ekim","Kasım","Aralık"]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                ZStack(alignment: .bottomLeading) {
                    LinearGradient(
                        colors: [Color(hex: "064E3B"), Color(hex: "065F46"), Color(hex: "0F172A")],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    .frame(height: DS.heroH)

                    Circle()
                        .fill(Color(hex: "10B981").opacity(0.20))
                        .frame(width: 180).blur(radius: 35)
                        .offset(x: UIScreen.main.bounds.width * 0.58, y: -20)

                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 110, weight: .black))
                        .foregroundColor(.white.opacity(0.04))
                        .offset(x: UIScreen.main.bounds.width * 0.44, y: 10)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Zam Hesaplayıcı")
                            .font(.system(size: 26, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                        Text("Net kazanımınızı ve vergi etkisini hesaplayın")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.55))
                    }
                    .padding(.horizontal, DS.lg)
                    .padding(.bottom, 20)
                }
                .frame(height: DS.heroH)
                .opacity(gorundu ? 1 : 0)
                .animation(.easeOut(duration: 0.4), value: gorundu)

                VStack(spacing: 18) {
                    girisKarti
                        .opacity(gorundu ? 1 : 0)
                        .offset(y: gorundu ? 0 : 14)
                        .animation(.spring(response: 0.5).delay(0.08), value: gorundu)

                    if hesaplandiMi {
                        ozetKartlari
                            .opacity(gorundu ? 1 : 0)
                            .animation(.spring(response: 0.5).delay(0.16), value: gorundu)
                        aylikKarsilastirma
                            .opacity(gorundu ? 1 : 0)
                            .animation(.spring(response: 0.5).delay(0.24), value: gorundu)
                    }
                    Color.clear.frame(height: 36)
                }
                .padding(.horizontal, DS.hPad)
                .padding(.top, 20)
            }
        }
        .background(appTheme.backgroundMain.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .contentShape(Rectangle())
        .simultaneousGesture(
            TapGesture().onEnded {
                mevcutBrutFocused = false
                zamSonrasiBrutFocused = false
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        )
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation { gorundu = true }
            }
        }
    }

    // MARK: Giriş Kartı
    private var girisKarti: some View {
        VStack(spacing: 16) {
            IKSectionHeader(title: "Zam Bilgileri", icon: "arrow.up.circle.fill",
                            color: Color(hex: "10B981"))

            HStack(spacing: 12) {
                inputAlani(
                    "Mevcut Brüt (₺)",
                    "240.000",
                    $mevcutBrutStr,
                    focused: $mevcutBrutFocused,
                    renk: Color(hex: "0EA5E9")
                )
                inputAlani(
                    "Zam Sonrası Brüt (₺)",
                    "280.000",
                    $zamSonrasiBrut,
                    focused: $zamSonrasiBrutFocused,
                    renk: Color(hex: "10B981")
                )
            }

            if mevcutBrut > 0 && zamSonrasiBrutVal > mevcutBrut {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.up.right.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "10B981"))
                    Text(String(format: "+%.1f%% zam · +%@ brüt artış", zamYuzdesi, formatTL(zamSonrasiBrutVal - mevcutBrut)))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "10B981"))
                    Spacer()
                }
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(Color(hex: "10B981").opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: DS.rSM, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 5) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color(hex: "10B981"))
                    Text("Zamın Başladığı Ay")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(appTheme.textSecondary)
                }
                .padding(.horizontal, 2)

                IKMonthSelector(selectedMonth: $zamAyi, color: Color(hex: "10B981"))
                    .padding(.horizontal, -DS.base)
            }
        }
        .padding(DS.base)
        .background(appTheme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: DS.rXL, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DS.rXL, style: .continuous)
            .stroke(appTheme.cardStroke.opacity(0.25), lineWidth: 1))
        .shadow(color: .black.opacity(appTheme.isLight ? 0.04 : 0), radius: 10, y: 3)
    }

    private func inputAlani(
        _ label: String,
        _ placeholder: String,
        _ binding: Binding<String>,
        focused: FocusState<Bool>.Binding,
        renk: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(appTheme.textSecondary)
            TextField(placeholder, text: binding)
                .keyboardType(.numberPad)
                .focused(focused)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(appTheme.textPrimary)
                .monospacedDigit()
                .padding(.horizontal, DS.md)
                .padding(.vertical, 12)
                .background(appTheme.isLight ? Color(white: 0.965) : Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: DS.rMD, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: DS.rMD, style: .continuous)
                    .stroke(renk.opacity(0.25), lineWidth: 1.2))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Özet Kartlar
    private var ozetKartlari: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: DS.rXL, style: .continuous)
                    .fill(LinearGradient(
                        colors: [Color(hex: "064E3B"), Color(hex: "065F46")],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                Circle()
                    .fill(Color.white.opacity(0.05)).frame(width: 120).blur(radius: 25)
                    .offset(x: UIScreen.main.bounds.width * 0.55, y: -20)

                VStack(alignment: .leading, spacing: 12) {
                    Text("AYLIK NET KAZANIM")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(.white.opacity(0.50))
                        .tracking(1.5)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("+")
                            .font(.system(size: 22, weight: .heavy))
                            .foregroundColor(.white.opacity(0.55))
                        Text(formatTL(aylikNetFark))
                            .font(.system(size: 34, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .monospacedDigit()
                    }

                    HStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Mevcut Net").font(.system(size: 9)).foregroundColor(.white.opacity(0.50))
                            Text(formatTL(aylikNetMevcut)).font(.system(size: 13, weight: .bold, design: .rounded)).foregroundColor(.white.opacity(0.75)).monospacedDigit()
                        }
                        Image(systemName: "arrow.right").font(.system(size: 11)).foregroundColor(.white.opacity(0.35))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Yeni Net").font(.system(size: 9)).foregroundColor(.white.opacity(0.50))
                            Text(formatTL(aylikNetYeni)).font(.system(size: 13, weight: .bold, design: .rounded)).foregroundColor(.white).monospacedDigit()
                        }
                    }
                }
                .padding(20)
            }
            .frame(height: 140)
            .shadow(color: Color(hex: "065F46").opacity(0.4), radius: 16, y: 6)

            HStack(spacing: 12) {
                kucukKart("Yıllık Net Kazanım", "+ " + formatTL(yillikNetFark),
                           "\(aylar[zamAyi-1])'dan itibaren", "calendar.badge.plus", Color(hex: "3B82F6"))
                kucukKart("Kalan Ay Kazanımı", formatTL(Double(13-zamAyi) * aylikNetFark),
                           "\(13-zamAyi) ay × \(formatTLKisa(aylikNetFark))", "clock.fill", Color(hex: "8B5CF6"))
            }

            vergiEtkisiNotu
        }
    }

    private func kucukKart(_ b: String, _ d: String, _ a: String, _ i: String, _ r: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: i).font(.system(size: 11, weight: .semibold)).foregroundColor(r)
                Text(b).font(.system(size: 11, weight: .semibold)).foregroundColor(appTheme.textSecondary)
            }
            Text(d).font(.system(size: 17, weight: .heavy, design: .rounded)).foregroundColor(r).monospacedDigit()
            Text(a).font(.system(size: 10)).foregroundColor(appTheme.textSecondary).lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.md)
        .background(appTheme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: DS.rLG, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DS.rLG, style: .continuous).stroke(r.opacity(0.18), lineWidth: 1))
    }

    private var vergiEtkisiNotu: some View {
        let zamAyiD = senaryoB.first { $0.ay == zamAyi }
        let oncAyD  = senaryoB.first { $0.ay == zamAyi - 1 }
        let yKM = zamAyiD?.kumulatifVergiMatrahi ?? 0
        let eKM = oncAyD?.kumulatifVergiMatrahi ?? 0
        let uyari: Bool
        let mesaj: String
        if yKM > 1_500_000 && eKM <= 1_500_000 { uyari = true; mesaj = "Bu ay %27 → %35 dilimine geçiyor" }
        else if yKM > 400_000 && eKM <= 400_000 { uyari = true; mesaj = "Bu ay %20 → %27 dilimine geçiyor" }
        else if yKM > 190_000 && eKM <= 190_000 { uyari = true; mesaj = "Bu ay %15 → %20 dilimine geçiyor" }
        else { uyari = false; mesaj = "" }
        let renk = uyari ? Color(hex: "F59E0B") : Color(hex: "3B82F6")
        let ikon = uyari ? "exclamationmark.triangle.fill" : "info.circle.fill"
        return HStack(alignment: .top, spacing: 10) {
            Image(systemName: ikon).font(.system(size: 13)).foregroundColor(renk).padding(.top, 1)
            VStack(alignment: .leading, spacing: 3) {
                Text(uyari ? mesaj : "Vergi dilimi değişmiyor")
                    .font(.system(size: 12, weight: .semibold)).foregroundColor(uyari ? renk : appTheme.textPrimary)
                Text(uyari
                     ? "Zam sonrası kümülatif matrah yeni dilime giriyor. Net kazanım kısmen azalıyor."
                     : "Tüm hesaplamalar kümülatif vergi matrahı ile yapıldı.")
                    .font(.system(size: 11)).foregroundColor(appTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true).lineSpacing(2)
            }
        }
        .padding(12)
        .background(renk.opacity(0.07))
        .cornerRadius(DS.rMD)
        .overlay(RoundedRectangle(cornerRadius: DS.rMD).stroke(renk.opacity(0.18), lineWidth: 1))
    }

    // MARK: Aylık Karşılaştırma
    private var aylikKarsilastirma: some View {
        VStack(alignment: .leading, spacing: 12) {
            IKSectionHeader(title: "Aylık Karşılaştırma", icon: "tablecells.fill", color: Color(hex: "8B5CF6"))

            VStack(spacing: 0) {
                HStack {
                    Text("Ay").frame(width: 50, alignment: .leading)
                    Spacer()
                    Text("Mevcut Net").frame(width: 88, alignment: .trailing)
                    Text("Yeni Net").frame(width: 88, alignment: .trailing)
                    Text("Fark").frame(width: 68, alignment: .trailing)
                }
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(appTheme.textSecondary)
                .padding(.horizontal, DS.md).padding(.vertical, 10)
                .background(Color(hex: "8B5CF6").opacity(0.08))

                ForEach(1...12, id: \.self) { ay in
                    let dA = senaryoA.first { $0.ay == ay }
                    let dB = senaryoB.first { $0.ay == ay }
                    let nA = dA?.toplamNetEleGecen ?? 0
                    let nB = dB?.toplamNetEleGecen ?? 0
                    let fark = nB - nA
                    let zamli = ay >= zamAyi

                    VStack(spacing: 0) {
                        HStack {
                            HStack(spacing: 4) {
                                if zamli { Circle().fill(Color(hex: "10B981")).frame(width: 5, height: 5) }
                                Text(String(aylar[ay-1].prefix(3)) + ".")
                                    .font(.system(size: 12, weight: zamli ? .semibold : .regular))
                                    .foregroundColor(zamli ? appTheme.textPrimary : appTheme.textSecondary)
                            }
                            .frame(width: 50, alignment: .leading)
                            Spacer()
                            Text(formatTLKisa(nA)).font(.system(size: 11, design: .monospaced))
                                .foregroundColor(appTheme.textSecondary).frame(width: 88, alignment: .trailing)
                            Text(formatTLKisa(nB)).font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundColor(zamli ? Color(hex: "10B981") : appTheme.textSecondary).frame(width: 88, alignment: .trailing)
                            Text(fark > 0 ? "+\(formatTLKisa(fark))" : "–")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(fark > 0 ? Color(hex: "10B981") : appTheme.textSecondary).frame(width: 68, alignment: .trailing)
                        }
                        .padding(.horizontal, DS.md).padding(.vertical, 10)
                        .background(zamli ? Color(hex: "10B981").opacity(0.04) : Color.clear)
                        if ay < 12 { Divider().padding(.leading, DS.md) }
                    }
                }

                Divider()
                HStack {
                    Text("TOPLAM").font(.system(size: 11, weight: .black)).foregroundColor(appTheme.textPrimary).frame(width: 50, alignment: .leading)
                    Spacer()
                    Text(formatTLKisa(yillikNetA)).font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundColor(appTheme.textSecondary).frame(width: 88, alignment: .trailing)
                    Text(formatTLKisa(yillikNetB)).font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundColor(appTheme.textPrimary).frame(width: 88, alignment: .trailing)
                    Text("+\(formatTLKisa(yillikNetFark))").font(.system(size: 11, weight: .black, design: .monospaced)).foregroundColor(Color(hex: "10B981")).frame(width: 68, alignment: .trailing)
                }
                .padding(.horizontal, DS.md).padding(.vertical, 12)
                .background(Color(hex: "10B981").opacity(0.06))
            }
            .background(appTheme.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: DS.rLG, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: DS.rLG, style: .continuous)
                .stroke(appTheme.cardStroke.opacity(0.25), lineWidth: 1))
        }
    }

    private func formatTL(_ d: Double) -> String {
        let f = NumberFormatter(); f.numberStyle = .decimal; f.locale = Locale(identifier: "tr_TR")
        f.minimumFractionDigits = 0; f.maximumFractionDigits = 0
        return (f.string(from: NSNumber(value: d)) ?? "0") + " ₺"
    }
    private func formatTLKisa(_ d: Double) -> String {
        if d >= 1_000_000 { return String(format: "%.2fM₺", d/1_000_000) }
        if d >= 1_000 { return String(format: "%.1fK₺", d/1_000) }
        return String(format: "%.0f₺", d)
    }
}
