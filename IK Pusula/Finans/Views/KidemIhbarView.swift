import SwiftUI
import UIKit

struct KidemIhbarView: View {
    @EnvironmentObject var appTheme: AppTheme
    @FocusState private var brutMaasFocused: Bool

    @State private var isGirisTarihi: Date = Calendar.current.date(byAdding: .year, value: -3, to: Date()) ?? Date()
    @State private var cikisTarihi: Date = Date()
    @State private var brutMaasStr  = ""
    @State private var cikisNedeni: CikisNedeni = .isveren
    @State private var gorundu = false

    private var brutMaas: Double {
        Double(brutMaasStr.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: "")) ?? 0
    }
    private var calismaSuresiGun: Int {
        max(0, Calendar.current.dateComponents([.day], from: isGirisTarihi, to: cikisTarihi).day ?? 0)
    }
    private var calismaSuresiYil: Double { Double(calismaSuresiGun) / 365.0 }
    private var tamYil: Int { Int(calismaSuresiYil) }
    private var kalanGun: Int { calismaSuresiGun - (tamYil * 365) }
    private var ihbarHaftasi: Int {
        let ay = calismaSuresiGun / 30
        switch ay {
        case 0..<6:   return 2
        case 6..<18:  return 4
        case 18..<36: return 6
        default:      return 8
        }
    }
    private var ihbarTazminatiBrut: Double {
        guard brutMaas > 0 else { return 0 }
        return ((brutMaas / 30.0) * Double(ihbarHaftasi) * 7).yuvarla()
    }
    private var ihbarTazminatiNet: Double {
        guard ihbarTazminatiBrut > 0 else { return 0 }
        return BrutNetCalculator.hesapla(brut: ihbarTazminatiBrut, kumulatifMatrah: 0).net
    }
    private var ihbarTazminati: Double { ihbarTazminatiNet }
    static let kidemTavani: Double = 64_948.77
    private var kidemTazminati: Double {
        guard brutMaas > 0, cikisNedeni.kidemHakkiVar else { return 0 }
        let etkin = min(brutMaas, Self.kidemTavani)
        let brut = (etkin * Double(tamYil) + etkin * (Double(kalanGun) / 365.0)).yuvarla()
        let damga = (brut * BrutNetCalculator.damgaOrani).yuvarla()
        return (brut - damga).yuvarla()
    }
    private var kidemTazminatiBrut: Double {
        guard brutMaas > 0, cikisNedeni.kidemHakkiVar else { return 0 }
        let etkin = min(brutMaas, Self.kidemTavani)
        return (etkin * Double(tamYil) + etkin * (Double(kalanGun) / 365.0)).yuvarla()
    }
    private var toplamTazminat: Double { kidemTazminati + (cikisNedeni.ihbarHakkiVar ? ihbarTazminati : 0) }
    private var sonCalismaGunu: Date {
        Calendar.current.date(byAdding: .day, value: ihbarHaftasi * 7, to: cikisTarihi) ?? cikisTarihi
    }
    private var hesaplandiMi: Bool { brutMaas > 0 && calismaSuresiGun > 30 }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                ZStack(alignment: .bottomLeading) {
                    LinearGradient(
                        colors: [Color(hex: "3B0764"), Color(hex: "4C1D95"), Color(hex: "0F172A")],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    .frame(height: DS.heroH)
                    Circle()
                        .fill(Color(hex: "8B5CF6").opacity(0.20))
                        .frame(width: 180).blur(radius: 36)
                        .offset(x: UIScreen.main.bounds.width * 0.56, y: -20)
                    Image(systemName: "briefcase.fill")
                        .font(.system(size: 110, weight: .black))
                        .foregroundColor(.white.opacity(0.04))
                        .offset(x: UIScreen.main.bounds.width * 0.44, y: 10)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Kıdem & İhbar Tazminatı")
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                        Text("2026 yasal tavanı · Vergi hesabı dahil")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.55))
                    }
                    .padding(.horizontal, DS.lg)
                    .padding(.bottom, 20)
                }
                .frame(height: DS.heroH)
                .opacity(gorundu ? 1 : 0)
                .animation(.easeOut(duration: 0.4), value: gorundu)

                VStack(spacing: 16) {
                    girisKarti
                        .opacity(gorundu ? 1 : 0)
                        .offset(y: gorundu ? 0 : 14)
                        .animation(.spring(response: 0.5).delay(0.08), value: gorundu)

                    if hesaplandiMi {
                        sonucKarti
                            .opacity(gorundu ? 1 : 0)
                            .animation(.spring(response: 0.5).delay(0.16), value: gorundu)
                        detayKarti
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
        // Klavye açıkken ekrana tıklayınca kapanması için
        .contentShape(Rectangle())
        .onTapGesture {
            brutMaasFocused = false
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation { gorundu = true }
            }
        }
    }

    // MARK: Giriş Kartı
    private var girisKarti: some View {
        VStack(spacing: 16) {
            IKSectionHeader(title: "Çalışma Bilgileri", icon: "briefcase.fill", color: Color(hex: "8B5CF6"))

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 5) {
                    Image(systemName: "turkishlirasign.circle.fill")
                        .font(.system(size: 10, weight: .semibold)).foregroundColor(Color(hex: "8B5CF6"))
                    Text("Brüt Maaş (₺)").font(.system(size: 11, weight: .semibold)).foregroundColor(appTheme.textSecondary)
                }
                TextField("64.000", text: $brutMaasStr)
                    .keyboardType(.numberPad)
                    .focused($brutMaasFocused)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(appTheme.textPrimary).monospacedDigit()
                    .onChange(of: brutMaasStr) { _, newValue in
                        let onlyDigits = newValue.filter { $0.isNumber }
                        if let num = Int(onlyDigits), num > 0 {
                            let f = NumberFormatter()
                            f.locale = Locale(identifier: "tr_TR")
                            f.numberStyle = .decimal
                            f.maximumFractionDigits = 0
                            let formatted = f.string(from: NSNumber(value: num)) ?? newValue
                            if formatted != newValue { brutMaasStr = formatted }
                        } else if onlyDigits.isEmpty {
                            brutMaasStr = ""
                        }
                    }
                    .padding(.horizontal, DS.md).padding(.vertical, 13)
                    .background(appTheme.isLight ? Color(white: 0.965) : Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: DS.rMD, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: DS.rMD, style: .continuous)
                        .stroke(Color(hex: "8B5CF6").opacity(0.25), lineWidth: 1.2))
            }

            HStack(spacing: 12) {
                tarihAlani("İşe Giriş", $isGirisTarihi, Color(hex: "3B82F6"))
                tarihAlani("Ayrılış Tarihi", $cikisTarihi, Color(hex: "F59E0B"))
            }

            if calismaSuresiGun > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "clock.fill").font(.system(size: 11)).foregroundColor(Color(hex: "3B82F6"))
                    Text("\(tamYil) yıl \(kalanGun) gün · \(ihbarHaftasi) hafta ihbar süresi")
                        .font(.system(size: 12, weight: .semibold)).foregroundColor(Color(hex: "3B82F6"))
                    Spacer()
                }
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(Color(hex: "3B82F6").opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: DS.rSM, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 5) {
                    Image(systemName: "list.bullet.clipboard")
                        .font(.system(size: 10, weight: .semibold)).foregroundColor(Color(hex: "8B5CF6"))
                    Text("Ayrılış Nedeni").font(.system(size: 11, weight: .semibold)).foregroundColor(appTheme.textSecondary)
                }
                .padding(.horizontal, 2)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(CikisNedeni.allCases, id: \.self) { neden in
                            let sec = cikisNedeni == neden
                            Button {
                                withAnimation(.spring(response: 0.25)) { cikisNedeni = neden }
                            } label: {
                                VStack(spacing: 3) {
                                    Text(neden.baslik)
                                        .font(.system(size: 12, weight: sec ? .bold : .medium))
                                        .foregroundColor(sec ? .white : appTheme.textPrimary)
                                    HStack(spacing: 3) {
                                        Image(systemName: neden.kidemHakkiVar ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .font(.system(size: 8))
                                            .foregroundColor(sec ? .white.opacity(0.8) : (neden.kidemHakkiVar ? Color(hex: "10B981") : Color(hex: "F87171")))
                                        Text("Kıdem").font(.system(size: 9)).foregroundColor(sec ? .white.opacity(0.7) : appTheme.textSecondary)
                                    }
                                }
                                .padding(.horizontal, 14).padding(.vertical, 10)
                                .background(sec ? Color(hex: "8B5CF6") : (appTheme.isLight ? Color(white: 0.95) : Color.white.opacity(0.07)))
                                .clipShape(RoundedRectangle(cornerRadius: DS.rMD, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: DS.rMD, style: .continuous)
                                    .stroke(sec ? Color(hex: "8B5CF6").opacity(0.5) : Color.clear, lineWidth: 1.5))
                                .shadow(color: sec ? Color(hex: "8B5CF6").opacity(0.3) : .clear, radius: 5, y: 2)
                            }
                            .buttonStyle(PressButtonStyle())
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
        }
        .padding(DS.base)
        .background(appTheme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: DS.rXL, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DS.rXL, style: .continuous)
            .stroke(appTheme.cardStroke.opacity(0.25), lineWidth: 1))
        .shadow(color: .black.opacity(appTheme.isLight ? 0.04 : 0), radius: 10, y: 3)
    }

    private func tarihAlani(_ label: String, _ binding: Binding<Date>, _ renk: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.system(size: 10, weight: .semibold)).foregroundColor(appTheme.textSecondary)
            DatePicker("", selection: binding, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .tint(renk)
                .padding(.horizontal, DS.md).padding(.vertical, 10)
                .background(appTheme.isLight ? Color(white: 0.965) : Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: DS.rMD, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: DS.rMD, style: .continuous)
                    .stroke(renk.opacity(0.22), lineWidth: 1.2))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Sonuç Kartı
    private var sonucKarti: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: DS.rXL, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color(hex: "1A0533"), Color(hex: "4C1D95").opacity(0.8)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
            Circle()
                .fill(Color(hex: "8B5CF6").opacity(0.22))
                .frame(width: 180).blur(radius: 36)
                .offset(x: UIScreen.main.bounds.width * 0.4, y: -30)

            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 10)).foregroundColor(Color(hex: "A78BFA"))
                    Text("HESAPLAMA SONUCU").font(.system(size: 9, weight: .black))
                        .foregroundColor(Color(hex: "A78BFA")).tracking(1.3)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("TOPLAM ALACAK").font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.42)).tracking(1.2)
                    Text(formatTL(toplamTazminat))
                        .font(.system(size: 38, weight: .heavy, design: .rounded))
                        .foregroundColor(.white).monospacedDigit()
                }

                HStack(spacing: 0) {
                    if cikisNedeni.kidemHakkiVar {
                        IKMetricBadge(label: "Kıdem (Net)", value: formatTLKisa(kidemTazminati), color: Color(hex: "34D399"))
                        Divider().background(Color.white.opacity(0.12)).padding(.vertical, 10)
                    }
                    if cikisNedeni.ihbarHakkiVar {
                        IKMetricBadge(label: "İhbar (Net)", value: formatTLKisa(ihbarTazminati), color: Color(hex: "60A5FA"))
                        Divider().background(Color.white.opacity(0.12)).padding(.vertical, 10)
                    }
                    IKMetricBadge(label: "Çalışma", value: "\(tamYil)y \(kalanGun)g", color: Color(hex: "F59E0B"))
                }
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: DS.rMD))
            }
            .padding(20)
        }
        .shadow(color: Color(hex: "4C1D95").opacity(0.35), radius: 20, y: 8)
    }

    // MARK: Detay Kartı
    private var detayKarti: some View {
        VStack(spacing: 0) {
            IKSectionHeader(title: "Hesaplama Detayı", icon: "doc.text.fill", color: Color(hex: "8B5CF6"))
                .padding(DS.base)

            Divider()

            VStack(spacing: 0) {
                if cikisNedeni.kidemHakkiVar {
                    detaySatiri("Kıdem Brüt", formatTL(kidemTazminatiBrut), .secondary)
                    detaySatiri("Damga Vergisi (‰7.59)", "- " + formatTL(kidemTazminatiBrut * BrutNetCalculator.damgaOrani), .danger)
                    detaySatiri("Kıdem Net", formatTL(kidemTazminati), .success)
                    Divider().padding(.leading, DS.base)
                }
                if cikisNedeni.ihbarHakkiVar {
                    detaySatiri("İhbar Brüt (\(ihbarHaftasi) hafta)", formatTL(ihbarTazminatiBrut), .secondary)
                    detaySatiri("GV + Damga Vergisi", "Kesildi", .danger)
                    detaySatiri("İhbar Net", formatTL(ihbarTazminati), .success)
                    Divider().padding(.leading, DS.base)
                }
                detaySatiri("Son Çalışma Günü", dateStr(sonCalismaGunu), .primary)
                detaySatiri("Yasal Tavan (2026/1)", formatTL(KidemIhbarView.kidemTavani) + "/ay", .secondary)
            }
        }
        .background(appTheme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: DS.rXL, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DS.rXL, style: .continuous)
            .stroke(appTheme.cardStroke.opacity(0.25), lineWidth: 1))
        .shadow(color: .black.opacity(appTheme.isLight ? 0.04 : 0), radius: 10, y: 3)
    }

    private enum DetayStyle { case primary, secondary, success, danger }
    private func detaySatiri(_ label: String, _ deger: String, _ stil: DetayStyle) -> some View {
        let fg: Color = {
            switch stil {
            case .primary:   return appTheme.textPrimary
            case .secondary: return appTheme.textSecondary
            case .success:   return Color(hex: "10B981")
            case .danger:    return Color(hex: "F87171")
            }
        }()
        return HStack {
            Text(label).font(.system(size: 13)).foregroundColor(appTheme.textSecondary)
            Spacer()
            Text(deger).font(.system(size: 13, weight: .semibold))
                .foregroundColor(fg)
        }
        .padding(.horizontal, DS.base).padding(.vertical, 12)
    }

    private func formatTL(_ d: Double) -> String {
        let f = NumberFormatter(); f.numberStyle = .decimal; f.locale = Locale(identifier: "tr_TR")
        f.minimumFractionDigits = 2; f.maximumFractionDigits = 2
        return (f.string(from: NSNumber(value: d)) ?? "0") + " ₺"
    }
    private func formatTLKisa(_ d: Double) -> String {
        if d >= 1_000_000 { return String(format: "%.1fM₺", d/1_000_000) }
        if d >= 1_000 { return String(format: "%.0fK₺", d/1_000) }
        return String(format: "%.0f₺", d)
    }
    private func dateStr(_ d: Date) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "tr_TR"); f.dateStyle = .medium
        return f.string(from: d)
    }
}

// MARK: - Çıkış Nedeni Enum
enum CikisNedeni: CaseIterable {
    case isveren
    case emeklilik
    case askerlik
    case evlilik
    case istifa

    var baslik: String {
        switch self {
        case .isveren:   return "İşveren Feshetti"
        case .emeklilik: return "Emeklilik"
        case .askerlik:  return "Askerlik"
        case .evlilik:   return "Evlilik (Kadın)"
        case .istifa:    return "Kendi İsteğiyle İstifa"
        }
    }

    var aciklama: String {
        switch self {
        case .isveren:   return "Haksız fesih, sürüm azaltma vb."
        case .emeklilik: return "SGK emeklilik hakkı kazanıldı"
        case .askerlik:  return "Askerlik görevi nedeniyle ayrılış"
        case .evlilik:   return "Evlilik tarihinden itibaren 1 yıl içinde"
        case .istifa:    return "İhbar bildirimi yaparak ayrılış"
        }
    }

    var kidemHakkiVar: Bool {
        switch self {
        case .istifa: return false
        default:      return true
        }
    }

    var ihbarHakkiVar: Bool {
        switch self {
        case .isveren: return true
        default:       return false
        }
    }
}
