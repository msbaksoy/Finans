// ================================================================
// OzgecmisFormViews_YENI.swift
// ================================================================
// Mevcut OzgecmisFormViews.swift ile TAMAMEN değiştir.
//
// Düzeltilen 8 madde:
// 1. Her formun altında "Kaydet & Devam Et" sticky butonu
// 2. Telefon: ülke kodu seçici (+90 default), OzgecmisKisisel.telefon
//    artık sadece numara, ulkeKodu ayrı field olarak yazılıyor
//    (Model değiştirilmeden: telefon "KOD|NUMARA" formatında saklanır,
//     PDF'te birleşik gösterilir — OzgecmisPDFRenderer düzeltmesi gerekir)
// 3. Doğum tarihi: "Tam tarih" veya "Sadece yıl" seçimi
// 4. Profesyonel Özet: yönlendirici hint banner
// 5. Diller: ekleme sonrası üstte chip satırı, kayıt göstergesi
// 6. İş deneyimi tarihi: "2,026" hatası düzeltildi (monthYearString)
// 7. İş deneyimi listesinde süre bilgisi: (4 yıl 6 ay)
// 8. Tüm form ekranları sıfırdan minimal kart tasarımı
//
// NOT: OzgecmisSection navigasyonu OzgecmisAnaView'de yapılıyor.
// Bu dosya sadece form view'larını içeriyor.
// ================================================================

import SwiftUI
import UIKit

// MARK: - Tasarım Sabitleri
private enum FDS {
    static let hPad:    CGFloat = 18
    static let vPad:    CGFloat = 14
    static let radius:  CGFloat = 14
    static let fieldH:  CGFloat = 50
    static let cardBG   = Color(.systemBackground)
    static let rowBG    = Color(.secondarySystemBackground)
    static let labelSz: CGFloat = 11
    static let ctaH:    CGFloat = 52
}

// MARK: - Ortak Alan Bileşenleri ─────────────────────────────────

/// Küçük section etiketi (BÜYÜK HARF, tracking)
private struct FLabel: View {
    let text: String
    @EnvironmentObject var appTheme: AppTheme
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: FDS.labelSz, weight: .semibold))
            .foregroundColor(appTheme.textSecondary)
            .tracking(0.6)
    }
}

/// Tek satır metin alanı — kart tasarımı
private struct FField: View {
    let label: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var placeholder: String = ""
    var autocap: TextInputAutocapitalization = .sentences
    var prefix: String? = nil        // telefon ülke kodu gibi sabit prefix

    @EnvironmentObject var appTheme: AppTheme
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            FLabel(text: label)
            HStack(spacing: 0) {
                if let p = prefix {
                    Text(p)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(appTheme.primaryAccent)
                        .padding(.leading, 14)
                        .padding(.trailing, 8)
                    Rectangle()
                        .fill(appTheme.cardStroke.opacity(0.4))
                        .frame(width: 1, height: 22)
                        .padding(.trailing, 8)
                }
                TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                    .font(.system(size: 15, weight: .medium))
                .keyboardType(keyboard)
                    .textInputAutocapitalization(autocap)
                    .focused($focused)
                    .foregroundColor(appTheme.textPrimary)
                    .padding(.leading, prefix == nil ? 14 : 0)
                    .padding(.trailing, 14)
            }
            .frame(height: FDS.fieldH)
            .background(FDS.cardBG)
            .clipShape(RoundedRectangle(cornerRadius: FDS.radius, style: .continuous))
                .overlay(
                RoundedRectangle(cornerRadius: FDS.radius, style: .continuous)
                    .stroke(focused ? appTheme.primaryAccent : appTheme.cardStroke.opacity(0.5),
                            lineWidth: focused ? 1.5 : 1)
            )
            .animation(.easeInOut(duration: 0.15), value: focused)
        }
    }
}

/// Çok satır metin alanı — justified, maddeleme desteği korundu
private struct FEditor: View {
    let label: String
    @Binding var text: String
    var hint: String? = nil
    var minH: CGFloat = 110

    @EnvironmentObject var appTheme: AppTheme
    @State private var focused = false
    @State private var dynH: CGFloat = 110
    @State private var bullet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                FLabel(text: label)
                if bullet {
                    Text("Maddeleme açık")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(appTheme.primaryAccent)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(Capsule().fill(appTheme.primaryAccent.opacity(0.12)))
                }
                Spacer()
                Button {
                    bullet.toggle()
                    if bullet {
                        if text.isEmpty { text = "• " }
                        else if !text.hasSuffix("• ") {
                            text.append(text.hasSuffix("\n") ? "• " : "\n• ")
                        }
                    }
                } label: {
                    Image(systemName: bullet ? "list.bullet.circle.fill" : "list.bullet.circle")
                        .font(.system(size: 18))
                        .foregroundColor(appTheme.primaryAccent)
                }
                .buttonStyle(.plain)
            }

            if let h = hint {
                Text(h)
                    .font(.system(size: 12))
                    .foregroundColor(appTheme.textSecondary)
                    .padding(10)
                    .background(appTheme.primaryAccent.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(appTheme.primaryAccent.opacity(0.18), lineWidth: 1)
                    )
            }

            JustifiedTextView(
                text: $text,
                isFocused: $focused,
                dynamicHeight: $dynH,
                foregroundColor: UIColor(appTheme.textPrimary)
            )
            .frame(height: max(minH, dynH))
            .padding(12)
            .background(FDS.cardBG)
            .clipShape(RoundedRectangle(cornerRadius: FDS.radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: FDS.radius, style: .continuous)
                    .stroke(focused ? appTheme.primaryAccent : appTheme.cardStroke.opacity(0.5),
                            lineWidth: focused ? 1.5 : 1)
            )
        }
    }
}

/// Tarih seçici butonu (Ay Yıl formatı)
private struct FDateButton: View {
    let label: String
    let value: String
    let action: () -> Void
    @EnvironmentObject var appTheme: AppTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            FLabel(text: label)
            Button(action: action) {
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(appTheme.primaryAccent)
                    Text(value.isEmpty ? "Seçiniz" : value)
                        .font(.system(size: 15, weight: value.isEmpty ? .regular : .medium))
                        .foregroundColor(value.isEmpty ? appTheme.textSecondary : appTheme.textPrimary)
                Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(appTheme.textSecondary.opacity(0.4))
                }
                .frame(height: FDS.fieldH)
                .padding(.horizontal, 14)
                .background(FDS.cardBG)
                .clipShape(RoundedRectangle(cornerRadius: FDS.radius, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: FDS.radius, style: .continuous)
                    .stroke(appTheme.cardStroke.opacity(0.5), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }
}

/// İkincil "Ekle" butonu
private struct FAddButton: View {
    let label: String
    let ikon: String
    let renk: Color
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: ikon)
                    .font(.system(size: 14, weight: .semibold))
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(renk)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(renk.opacity(0.09))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(renk.opacity(0.20), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

/// Sticky "Kaydet & Devam Et" barı
private struct FBottomBar: View {
    let section: OzgecmisSection
    let renk: Color
    let onSave: () -> Void
    @EnvironmentObject var appTheme: AppTheme

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(appTheme.cardStroke.opacity(0.25))
                .frame(height: 0.5)
                                VStack(spacing: 6) {
                Button(action: onSave) {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Kaydet & Devam Et")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: FDS.ctaH)
                    .background(renk)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: renk.opacity(0.28), radius: 8, y: 3)
                }
                .buttonStyle(PressButtonStyle())
                Text("Veriler otomatik kaydediliyor")
                    .font(.system(size: 11))
                                        .foregroundColor(appTheme.textSecondary)
                                }
            .padding(.horizontal, FDS.hPad)
            .padding(.vertical, 12)
            .background(appTheme.backgroundMain)
        }
    }
}

// MARK: - Progress Bar ──────────────────────────────────────────
private struct FSectionProgress: View {
    let current: Int
    let total: Int
    let renk: Color
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(Color(.systemGray5)).frame(height: 3)
                Rectangle()
                    .fill(renk)
                    .frame(width: geo.size.width * CGFloat(current) / CGFloat(total), height: 3)
                    .animation(.spring(response: 0.4), value: current)
            }
        }
        .frame(height: 3)
    }
}

// MARK: - İzin Verilen Bölüm Sırası ────────────────────────────
private let sectionSirasi: [OzgecmisSection] = OzgecmisSection.allCases

private func sonrakiBolum(from s: OzgecmisSection) -> OzgecmisSection? {
    guard let i = sectionSirasi.firstIndex(of: s), i + 1 < sectionSirasi.count else { return nil }
    return sectionSirasi[i + 1]
}

private func bolumIndex(_ s: OzgecmisSection) -> Int {
    sectionSirasi.firstIndex(of: s).map { $0 + 1 } ?? 1
}

// MARK: - Ülke Kodu Listesi ─────────────────────────────────────
private struct UlkeKodu: Identifiable {
    let id: String
    let bayrak: String
    let kod: String
    let ulke: String
}

private let ulkeKodlari: [UlkeKodu] = [
    UlkeKodu(id: "TR", bayrak: "🇹🇷", kod: "+90",  ulke: "Türkiye"),
    UlkeKodu(id: "DE", bayrak: "🇩🇪", kod: "+49",  ulke: "Almanya"),
    UlkeKodu(id: "GB", bayrak: "🇬🇧", kod: "+44",  ulke: "İngiltere"),
    UlkeKodu(id: "US", bayrak: "🇺🇸", kod: "+1",   ulke: "ABD"),
    UlkeKodu(id: "NL", bayrak: "🇳🇱", kod: "+31",  ulke: "Hollanda"),
    UlkeKodu(id: "FR", bayrak: "🇫🇷", kod: "+33",  ulke: "Fransa"),
    UlkeKodu(id: "AZ", bayrak: "🇦🇿", kod: "+994", ulke: "Azerbaycan"),
    UlkeKodu(id: "SA", bayrak: "🇸🇦", kod: "+966", ulke: "Suudi Arabistan"),
    UlkeKodu(id: "AE", bayrak: "🇦🇪", kod: "+971", ulke: "BAE"),
    UlkeKodu(id: "QA", bayrak: "🇶🇦", kod: "+974", ulke: "Katar"),
    UlkeKodu(id: "AU", bayrak: "🇦🇺", kod: "+61",  ulke: "Avustralya"),
    UlkeKodu(id: "CA", bayrak: "🇨🇦", kod: "+1",   ulke: "Kanada"),
    UlkeKodu(id: "JP", bayrak: "🇯🇵", kod: "+81",  ulke: "Japonya"),
]

/// Telefon numarasını "KOD|NUMARA" biçiminde birleştirir → CV'de "KOD NUMARA"
private func telefonBirlestir(kod: String, numara: String) -> String {
    let n = numara.trimmingCharacters(in: .whitespaces)
    guard !n.isEmpty else { return "" }
    return "\(kod)|\(n)"
}

/// Saklanan "KOD|NUMARA" → (kod, numara)
private func telefonAyir(_ birlesik: String) -> (kod: String, numara: String) {
    let parts = birlesik.split(separator: "|", maxSplits: 1).map(String.init)
    if parts.count == 2 { return (parts[0], parts[1]) }
    // Eski format (kod yoksa): default +90 ata
    return ("+90", birlesik)
}

// MARK: - Ülke Kodu Seçici ──────────────────────────────────────
private struct UlkeKoduSecici: View {
    @Binding var secilenKod: String
    @State private var showSheet = false
    @EnvironmentObject var appTheme: AppTheme

    private var secilen: UlkeKodu {
        ulkeKodlari.first { $0.kod == secilenKod } ?? ulkeKodlari[0]
    }

    var body: some View {
        Button { showSheet = true } label: {
            HStack(spacing: 5) {
                Text(secilen.bayrak).font(.system(size: 18))
                Text(secilen.kod)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(appTheme.primaryAccent)
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .bold))
                                .foregroundColor(appTheme.textSecondary)
                        }
            .padding(.horizontal, 10).padding(.vertical, 8)
            .background(appTheme.primaryAccent.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showSheet) {
            NavigationStack {
                List(ulkeKodlari) { u in
                    Button {
                        secilenKod = u.kod
                        showSheet = false
                    } label: {
                        HStack(spacing: 12) {
                            Text(u.bayrak).font(.system(size: 20))
                            VStack(alignment: .leading, spacing: 1) {
                                Text(u.ulke)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(appTheme.textPrimary)
                                Text(u.kod)
                                    .font(.system(size: 12))
                                .foregroundColor(appTheme.textSecondary)
                        }
                            Spacer()
                            if u.kod == secilenKod {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(appTheme.primaryAccent)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color(.systemBackground))
                }
                .listStyle(.plain)
                .navigationTitle("Ülke Kodu")
                .navigationBarTitleDisplayMode(.inline)
            }
            .environmentObject(appTheme)
        }
    }
}

// MARK: - Doğum Tarihi Seçici ───────────────────────────────────
private struct DogumTarihiAlani: View {
    @Binding var deger: String
    @EnvironmentObject var appTheme: AppTheme
    @State private var sadeceyil = false
    @State private var yilText = ""
    @State private var tamTarih = Date()
    @State private var showPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            FLabel(text: "Doğum Tarihi")
            // Mod seçici
            HStack(spacing: 8) {
                modButon("Tam tarih", secili: !sadeceyil) { sadeceyil = false }
                modButon("Sadece yıl", secili: sadeceyil) { sadeceyil = true }
            }

            if sadeceyil {
                // Sadece yıl
                FField(
                    label: "DOĞUM YILI",
                    text: $yilText,
                    keyboard: .numberPad,
                    placeholder: "Örn: 1992"
                )
                .onChange(of: yilText) { _, v in deger = v }
                .onAppear {
                    // Eğer deger sadece 4 hane ise yil olarak al
                    if deger.count == 4 { yilText = deger }
                }
            } else {
                // Tam tarih
                Button {
                    showPicker = true
                } label: {
                        HStack {
                        Image(systemName: "calendar")
                            .font(.system(size: 14))
                            .foregroundColor(appTheme.primaryAccent)
                        Text(deger.isEmpty ? "Tarih seç" : deger)
                            .font(.system(size: 15, weight: deger.isEmpty ? .regular : .medium))
                            .foregroundColor(deger.isEmpty ? appTheme.textSecondary : appTheme.textPrimary)
                            Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11))
                            .foregroundColor(appTheme.textSecondary.opacity(0.4))
                    }
                    .frame(height: FDS.fieldH)
                    .padding(.horizontal, 14)
                    .background(FDS.cardBG)
                    .clipShape(RoundedRectangle(cornerRadius: FDS.radius, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: FDS.radius, style: .continuous)
                        .stroke(appTheme.cardStroke.opacity(0.5), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            Text("İstersen yalnızca doğum yılını girebilirsin.")
                .font(.system(size: 11))
                            .foregroundColor(appTheme.textSecondary)
                    }
        .sheet(isPresented: $showPicker) {
            TamTarihPickerView(date: $tamTarih, onDone: { d in
                tamTarih = d
                deger = tamTarihStr(d)
                showPicker = false
            }, onCancel: { showPicker = false }, theme: appTheme)
        }
    }

    private func modButon(_ title: String, secili: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(secili ? appTheme.primaryAccent : appTheme.textSecondary)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(secili ? appTheme.primaryAccent.opacity(0.10) : Color(.systemGray6))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(secili ? appTheme.primaryAccent.opacity(0.30) : Color.clear, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func tamTarihStr(_ d: Date) -> String {
        let cal = Calendar.current
        let day = cal.component(.day, from: d)
        let monthFormatter = DateFormatter()
        monthFormatter.locale = Locale(identifier: "tr_TR")
        monthFormatter.dateFormat = "MMMM"
        let month = monthFormatter.string(from: d)
        let year = cal.component(.year, from: d)
        // Yılı DateFormatter ile basmak tr_TR'de "2,026" üretebildiği için Int olarak birleştiriyoruz.
        return "\(day) \(month) \(year)"
    }
}

private struct TamTarihPickerView: View {
    @Binding var date: Date
    let onDone: (Date) -> Void
    let onCancel: () -> Void
    let theme: AppTheme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                DatePicker("", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
            }
            .navigationTitle("Doğum Tarihi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") { onCancel(); dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Tamam") { onDone(date); dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Çalışma Süresi Hesapla ────────────────────────────────
private func calismaSuresi(baslangic: String, bitis: String, devamEdiyor: Bool) -> String? {
    guard !baslangic.isEmpty else { return nil }

    let f = DateFormatter()
    f.locale = Locale(identifier: "tr_TR")
    f.dateFormat = "MMMM yyyy"

    guard let start = f.date(from: baslangic) else { return nil }
    let end: Date = {
        if devamEdiyor { return Date() }
        guard !bitis.isEmpty, let d = f.date(from: bitis) else { return Date() }
        return d
    }()

    let cal = Calendar.current
    let diff = cal.dateComponents([.year, .month], from: start, to: end)
    let yil  = diff.year  ?? 0
    let ay   = diff.month ?? 0

    if yil == 0 && ay == 0 { return nil }
    if yil == 0 { return "\(ay) ay" }
    if ay  == 0 { return "\(yil) yıl" }
    return "\(yil) yıl \(ay) ay"
}

// MARK: - Ay Yıl Formatlayıcı (2,026 hatasını düzeltir) ─────────
private func ozgAyYilStr(from date: Date) -> String {
    let f = DateFormatter()
    f.locale = Locale(identifier: "tr_TR")
    f.dateFormat = "MMMM"
    let ay = f.string(from: date)
    // Yılı doğrudan Calendar'den alarak Locale'in binlik ayraç koymasını engelle
    let yil = Calendar.current.component(.year, from: date)
    return "\(ay) \(yil)"
}

// MARK: ═══════════════════════════════════════════════════════
// MARK: 1. KİŞİSEL BİLGİLER
// ═══════════════════════════════════════════════════════════
struct OzgecmisKisiselFormView: View {
    @EnvironmentObject var appTheme: AppTheme
    @EnvironmentObject var store: OzgecmisStore
    var onDevamEt: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    @State private var showTecilPicker = false
    @State private var tecilDate = Date()
    @State private var showImagePicker = false
    @State private var showCropView = false
    @State private var imageForPicker: UIImage?
    @State private var imageToCrop: UIImage?
    @State private var profilFotografi: UIImage?
    @State private var ulkeKodu = "+90"
    @State private var telefonNumara = ""

    private let sekIdx = bolumIndex(.kisisel)

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    FSectionProgress(current: sekIdx, total: sectionSirasi.count, renk: OzgecmisSection.kisisel.renk)

                    VStack(alignment: .leading, spacing: 18) {
                        // Profil fotoğrafı
                        fotoAlani
                            .padding(.top, 20)

                        FField(label: "Ad Soyad", text: $store.draft.kisisel.adSoyad,
                               placeholder: "Örn: Ahmet Yılmaz", autocap: .words)

                        // E-posta
                        VStack(alignment: .leading, spacing: 4) {
                            FField(label: "E-posta", text: $store.draft.kisisel.email,
                                   keyboard: .emailAddress, placeholder: "ornek@eposta.com", autocap: .never)
                            if store.draft.kisisel.email.contains(" ") {
                                Text("E-posta adresinde boşluk olmamalıdır.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.red)
                            }
                        }

                        // Telefon + ülke kodu
                VStack(alignment: .leading, spacing: 6) {
                            FLabel(text: "Telefon")
                            HStack(spacing: 10) {
                                UlkeKoduSecici(secilenKod: $ulkeKodu)
                                TextField("532 111 11 11", text: $telefonNumara)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 15, weight: .medium))
                                    .keyboardType(.phonePad)
                                    .foregroundColor(appTheme.textPrimary)
                                    .padding(.horizontal, 14)
                                    .frame(height: FDS.fieldH)
                                    .background(FDS.cardBG)
                                    .clipShape(RoundedRectangle(cornerRadius: FDS.radius, style: .continuous))
                                    .overlay(RoundedRectangle(cornerRadius: FDS.radius, style: .continuous)
                                        .stroke(appTheme.cardStroke.opacity(0.5), lineWidth: 1))
                            }
                        }
                        .onChange(of: ulkeKodu)   { _, _ in kaydedTelefon() }
                        .onChange(of: telefonNumara) { _, _ in kaydedTelefon() }

                        // Doğum tarihi
                        DogumTarihiAlani(deger: $store.draft.kisisel.dogumTarihi)

                        // Şehir + Ülke yan yana
                        HStack(spacing: 12) {
                            FField(label: "Şehir / İlçe", text: $store.draft.kisisel.sehirIlce,
                                   placeholder: "İstanbul")
                                .frame(maxWidth: .infinity)
                            FField(label: "Ülke", text: $store.draft.kisisel.ulke,
                                   placeholder: "Türkiye")
                                .frame(maxWidth: .infinity)
                        }

                        FField(label: "LinkedIn", text: $store.draft.kisisel.linkedIn,
                               keyboard: .URL, placeholder: "linkedin.com/in/...", autocap: .never)
                        FField(label: "Web Sitesi", text: $store.draft.kisisel.webSitesi,
                               keyboard: .URL, placeholder: "musabaksoy.com", autocap: .never)

                        surucuPicker
                        askerlikPicker
                        medeniPicker
                        FField(label: "Sosyal Medya", text: $store.draft.kisisel.sosyalMedya,
                               placeholder: "@kullanici")

                        Color.clear.frame(height: 90)
                    }
                    .padding(.horizontal, FDS.hPad)
                }
            }
            .background(appTheme.backgroundMain.ignoresSafeArea())

            if let onDevamEt {
                FBottomBar(section: .kisisel, renk: OzgecmisSection.kisisel.renk) {
                    store.manuelKaydet()
                    onDevamEt()
                }
            }
        }
        .sheet(isPresented: $showTecilPicker) {
            MonthYearFuturePickerView(
                title: "Tecil Bitiş Tarihi", date: $tecilDate,
                onDone: { d in
                    let now = Date()
                    tecilDate = d < now ? now : d
                    store.draft.kisisel.askerlikTecilBitis = ozgAyYilStr(from: tecilDate)
                    showTecilPicker = false
                },
                onCancel: { showTecilPicker = false },
                theme: appTheme
            )
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $imageForPicker)
        }
        .onChange(of: imageForPicker) { _, new in
            guard let img = new else { return }
            imageToCrop = img
            imageForPicker = nil
            DispatchQueue.main.async {
                showCropView = true
            }
        }
        .fullScreenCover(isPresented: $showCropView) {
            Group {
                if let src = imageToCrop {
                    CircularPhotoCropView(sourceImage: src, onSave: { cropped in
                        saveCvPhoto(cropped)
                        profilFotografi = cropped
                        imageToCrop = nil
                    }, onCancel: {
                        imageToCrop = nil
                    })
                }
            }
        }
        .onAppear {
            profilFotografi = loadCvPhoto()
            let (kod, numara) = telefonAyir(store.draft.kisisel.telefon)
            ulkeKodu = kod.isEmpty ? "+90" : kod
            telefonNumara = numara
        }
    }

    private func kaydedTelefon() {
        store.draft.kisisel.telefon = telefonBirlestir(kod: ulkeKodu, numara: telefonNumara)
    }

    private var fotoAlani: some View {
        VStack(spacing: 8) {
            Button { showImagePicker = true } label: {
                ZStack {
                    if let img = profilFotografi {
                        Image(uiImage: img).resizable().scaledToFill()
                            .frame(width: 120, height: 120).clipShape(Circle())
                            .overlay(Circle().stroke(OzgecmisSection.kisisel.renk, lineWidth: 2))
                    } else {
                        Circle().fill(Color(.systemGray6)).frame(width: 120, height: 120)
                        VStack(spacing: 4) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 26))
                                .foregroundColor(appTheme.textSecondary)
                            Text("Fotoğraf Ekle")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(appTheme.textSecondary)
                        }
                    }
                }
                .frame(width: 120, height: 120).frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            if profilFotografi != nil {
                Button { removeCvPhoto(); profilFotografi = nil } label: {
                    Text("Fotoğrafı Kaldır")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var surucuPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            FLabel(text: "Sürücü Belgesi")
            Picker("", selection: $store.draft.kisisel.surucuBelgesi) {
                Text("Yok / Seçilmedi").tag("")
                ForEach(["A1","A2","A","B1","B","BE","C1","C1E","C","CE","D1","D1E","D","DE","F","M","G"], id: \.self) { c in
                    Text(c).tag(c)
                }
            }
            .pickerStyle(.menu)
            .font(.system(size: 14))
            .padding(.horizontal, 12).frame(height: FDS.fieldH)
            .background(FDS.cardBG)
            .clipShape(RoundedRectangle(cornerRadius: FDS.radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: FDS.radius, style: .continuous)
                .stroke(appTheme.cardStroke.opacity(0.5), lineWidth: 1))
        }
    }

    private var askerlikPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            FLabel(text: "Askerlik Durumu")
            Picker("", selection: $store.draft.kisisel.askerlikDurumu) {
                Text("Belirtmek İstemiyorum").tag("")
                Text("Yapıldı").tag("Yapıldı")
                Text("Muaf").tag("Muaf")
                Text("Tecilli").tag("Tecilli")
            }
            .pickerStyle(.segmented)

            if store.draft.kisisel.askerlikDurumu == "Tecilli" {
                FDateButton(
                    label: "Tecil Bitiş Tarihi",
                    value: store.draft.kisisel.askerlikTecilBitis
                ) { tecilDate = Date(); showTecilPicker = true }
            }
        }
    }

    private var medeniPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            FLabel(text: "Medeni Durum")
            Picker("", selection: $store.draft.kisisel.medeniDurum) {
                Text("Belirtmek İstemiyorum").tag("")
                Text("Bekâr").tag("Bekâr")
                Text("Evli").tag("Evli")
            }
            .pickerStyle(.segmented)
        }
    }

    // Foto işlemleri (değişmedi)
    private func loadCvPhoto() -> UIImage? {
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        guard let data = try? Data(contentsOf: dir.appendingPathComponent("cv_photo.jpg")) else { return nil }
        return UIImage(data: data)
    }
    private func saveCvPhoto(_ img: UIImage) {
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
              let data = img.jpegData(compressionQuality: 0.92) else { return }
        try? data.write(to: dir.appendingPathComponent("cv_photo.jpg"))
    }
    private func removeCvPhoto() {
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        try? FileManager.default.removeItem(at: dir.appendingPathComponent("cv_photo.jpg"))
    }
}

// MARK: ═══════════════════════════════════════════════════════
// MARK: 2. PROFESYONEL ÖZET
// ═══════════════════════════════════════════════════════════
struct OzgecmisOzetFormView: View {
    @EnvironmentObject var appTheme: AppTheme
    @EnvironmentObject var store: OzgecmisStore
    var onDevamEt: (() -> Void)? = nil

    private let sekIdx = bolumIndex(.ozet)

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    FSectionProgress(current: sekIdx, total: sectionSirasi.count, renk: OzgecmisSection.ozet.renk)

                    VStack(alignment: .leading, spacing: 18) {
                        Color.clear.frame(height: 8)
                        AIProfesyonelOzetButton()
                            .padding(.bottom, 2)

                        FEditor(
                            label: "Profesyonel Özet",
                            text: $store.draft.ozet,
                            hint: "Kendinizden ve yaptığınız işten birkaç cümleyle bahsedin. Kaç yıldır ne alanda çalıştığınızı, güçlü yönlerinizi ve kariyer hedefinizi kısaca aktarabilirsiniz. 3–5 cümle yeterlidir.",
                            minH: 160
                        )

                VStack(alignment: .leading, spacing: 8) {
                            FLabel(text: "Özet CV'de Nerede Görünsün?")
                    Picker("", selection: $store.draft.ozetKonum) {
                        Text("Sol panelde").tag(OzgecmisOzetKonum.solPanel)
                        Text("Sağ panel en üstte").tag(OzgecmisOzetKonum.sagUst)
                    }
                    .pickerStyle(.segmented)
                }

                        Color.clear.frame(height: 90)
                    }
                    .padding(.horizontal, FDS.hPad)
                }
            }
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .background(appTheme.backgroundMain.ignoresSafeArea())

            if let onDevamEt {
                FBottomBar(section: .ozet, renk: OzgecmisSection.ozet.renk) {
                    store.manuelKaydet()
                    onDevamEt()
                }
            }
        }
    }
}

// MARK: ═══════════════════════════════════════════════════════
// MARK: 3. İŞ DENEYİMİ
// ═══════════════════════════════════════════════════════════
struct OzgecmisDeneyimFormView: View {
    @EnvironmentObject var appTheme: AppTheme
    @EnvironmentObject var store: OzgecmisStore
    var onDevamEt: (() -> Void)? = nil
    @State private var editorDeneyim: OzgecmisDeneyim?
    @State private var showOnay = false
    @State private var silinecekID: UUID?

    private let sekIdx = bolumIndex(.deneyim)

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    FSectionProgress(current: sekIdx, total: sectionSirasi.count, renk: OzgecmisSection.deneyim.renk)

                    VStack(spacing: 14) {
                        Color.clear.frame(height: 8)

            if store.draft.isDeneyimleri.isEmpty {
                            emptyState
            } else {
                    ForEach(store.draft.isDeneyimleri) { d in
                                deneyimKarti(d)
                            }
                        }

                        FAddButton(
                            label: "Deneyim Ekle",
                            ikon: "plus.circle.fill",
                            renk: OzgecmisSection.deneyim.renk
                        ) { editorDeneyim = OzgecmisDeneyim() }

                        Color.clear.frame(height: 90)
                    }
                    .padding(.horizontal, FDS.hPad)
                }
            }
            .background(appTheme.backgroundMain.ignoresSafeArea())

            if let onDevamEt {
                FBottomBar(section: .deneyim, renk: OzgecmisSection.deneyim.renk) {
                    store.manuelKaydet()
                    onDevamEt()
                }
            }
        }
        .fullScreenCover(item: $editorDeneyim) { d in
            OzgecmisDeneyimEditView(
                deneyim: d,
                onCancel: { editorDeneyim = nil },
                onSave: { updated in
                    if let i = store.draft.isDeneyimleri.firstIndex(where: { $0.id == updated.id }) {
                        store.draft.isDeneyimleri[i] = updated
                    } else {
                        store.draft.isDeneyimleri.append(updated)
                    }
                    editorDeneyim = nil
                }
            )
            .environmentObject(appTheme)
            .environmentObject(store)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "briefcase")
                .font(.system(size: 40))
                .foregroundColor(appTheme.textSecondary.opacity(0.4))
            Text("Henüz iş deneyimi eklenmedi")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(appTheme.textSecondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 40)
    }

    private func deneyimKarti(_ d: OzgecmisDeneyim) -> some View {
        // 7. Madde: Süre hesabı
        let sure = calismaSuresi(baslangic: d.baslangic, bitis: d.bitis, devamEdiyor: d.halaDevamEdiyor)

        return Button { editorDeneyim = d } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(OzgecmisSection.deneyim.renk.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "briefcase.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(OzgecmisSection.deneyim.renk)
                }

                VStack(alignment: .leading, spacing: 3) {
                    // Unvan + süre (madde 7)
                    HStack(spacing: 6) {
                        Text(d.unvan.isEmpty ? "İş Deneyimi" : d.unvan)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(appTheme.textPrimary)
                        if let s = sure {
                            Text("(\(s))")
                                .font(.system(size: 12))
                                .foregroundColor(appTheme.textSecondary)
                        }
                    }

                    if !d.sirket.isEmpty {
                        Text(d.sirket)
                            .font(.system(size: 12))
                            .foregroundColor(appTheme.textSecondary)
                    }

                    // Tarihler
                    let tarihStr = altSatirTarih(d)
                    if !tarihStr.isEmpty {
                        Text(tarihStr)
                            .font(.system(size: 11))
                            .foregroundColor(appTheme.textSecondary.opacity(0.7))
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(appTheme.textSecondary.opacity(0.3))
            }
            .padding(14)
            .background(appTheme.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(appTheme.cardStroke.opacity(0.35), lineWidth: 1))
            .shadow(color: .black.opacity(appTheme.isLight ? 0.04 : 0), radius: 8, y: 2)
        }
        .buttonStyle(PressButtonStyle())
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                store.draft.isDeneyimleri.removeAll { $0.id == d.id }
            } label: { Label("Sil", systemImage: "trash") }
        }
    }

    private func altSatirTarih(_ d: OzgecmisDeneyim) -> String {
            if d.baslangic.isEmpty && d.bitis.isEmpty { return "" }
            if d.halaDevamEdiyor {
            return d.baslangic.isEmpty ? "Devam ediyor" : "\(d.baslangic) – Devam ediyor"
        }
        if d.bitis.isEmpty  { return d.baslangic }
        if d.baslangic.isEmpty { return d.bitis }
        return "\(d.baslangic) – \(d.bitis)"
    }
}

// MARK: - Deneyim Düzenleme
private struct OzgecmisDeneyimEditView: View {
    @EnvironmentObject var appTheme: AppTheme
    @State private var form: OzgecmisDeneyim
    @State private var startDate = Date()
    @State private var endDate   = Date()
    @State private var showStart = false
    @State private var showEnd   = false
    let onCancel: () -> Void
    let onSave: (OzgecmisDeneyim) -> Void

    init(deneyim: OzgecmisDeneyim, onCancel: @escaping () -> Void, onSave: @escaping (OzgecmisDeneyim) -> Void) {
        _form = State(initialValue: deneyim)
        self.onCancel = onCancel
        self.onSave   = onSave
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    FField(label: "Pozisyon", text: Binding(get: { form.unvan }, set: { form.unvan = titleCased($0) }),
                           placeholder: "Örn: Finans Uzmanı", autocap: .words)
                        .environmentObject(appTheme)

                    FField(label: "Firma Adı", text: Binding(get: { form.sirket }, set: { form.sirket = titleCased($0) }),
                           placeholder: "Örn: Türkiye Finans", autocap: .words)
                        .environmentObject(appTheme)

                    Toggle("Hâlâ çalışıyorum", isOn: $form.halaDevamEdiyor)
                        .font(.system(size: 15))
                        .foregroundColor(appTheme.textPrimary)

                    // Başlangıç tarihi (madde 6: ozgAyYilStr)
                    FDateButton(label: "Başlangıç (Ay / Yıl)", value: form.baslangic) { showStart = true }
                        .environmentObject(appTheme)

                    if !form.halaDevamEdiyor {
                        FDateButton(label: "Bitiş (Ay / Yıl)", value: form.bitis) { showEnd = true }
                            .environmentObject(appTheme)
                    }

                    DisclosureGroup {
                        VStack(spacing: 12) {
                            FField(label: "Sektör", text: $form.firmaSektoru, placeholder: "Örn: Bankacılık")
                                .environmentObject(appTheme)
                            FField(label: "Departman", text: Binding(get: { form.departman }, set: { form.departman = titleCased($0) }),
                                   placeholder: "Örn: Finans", autocap: .words)
                                .environmentObject(appTheme)
                            FField(label: "Çalışma Şekli", text: $form.calismaSekli, placeholder: "Örn: Tam Zamanlı")
                                .environmentObject(appTheme)
                            FField(label: "Şehir", text: $form.sehirIlce, placeholder: "İstanbul")
                                .environmentObject(appTheme)
                        }
                        .padding(.top, 8)
                    } label: {
                        Text("Diğer Bilgiler (isteğe bağlı)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(appTheme.textSecondary)
                    }

                    FEditor(label: "Açıklama", text: $form.aciklama, minH: 140)
                        .environmentObject(appTheme)
                }
                .padding(FDS.hPad)
            }
            .background(appTheme.backgroundMain.ignoresSafeArea())
            .navigationTitle("İş Deneyimi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç", action: onCancel).foregroundColor(appTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") { onSave(form) }
                    .fontWeight(.semibold)
                        .foregroundColor(appTheme.primaryAccent)
                }
            }
            .sheet(isPresented: $showStart) {
                MonthYearPickerView(title: "Başlangıç", date: $startDate, onDone: { d in
                    let now = Date(); startDate = d > now ? now : d
                    form.baslangic = ozgAyYilStr(from: startDate)
                    showStart = false
                    if !form.halaDevamEdiyor { showEnd = true }
                }, onCancel: { showStart = false }, theme: appTheme)
            }
            .sheet(isPresented: $showEnd) {
                MonthYearPickerView(title: "Bitiş", date: $endDate, onDone: { d in
                    endDate = d
                    form.bitis = ozgAyYilStr(from: endDate)
                    showEnd = false
                }, onCancel: { showEnd = false }, theme: appTheme)
            }
        }
    }

    private func titleCased(_ s: String) -> String {
        s.split(whereSeparator: \.isWhitespace).map { w -> String in
            let low = w.lowercased()
            if low == "ve" { return "ve" }
            return String(w.prefix(1)).uppercased() + String(w.dropFirst())
        }.joined(separator: " ")
    }
}

// MARK: ═══════════════════════════════════════════════════════
// MARK: 4. EĞİTİM
// ═══════════════════════════════════════════════════════════
struct OzgecmisEgitimFormView: View {
    @EnvironmentObject var appTheme: AppTheme
    @EnvironmentObject var store: OzgecmisStore
    var onDevamEt: (() -> Void)? = nil
    @State private var showTipSecimi = false
    @State private var editorEgitim: OzgecmisEgitim?

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    FSectionProgress(current: bolumIndex(.egitim), total: sectionSirasi.count, renk: OzgecmisSection.egitim.renk)
                    VStack(spacing: 14) {
                        Color.clear.frame(height: 8)
                        ForEach(store.draft.egitimler) { e in
                            Button { editorEgitim = e } label: {
                                egitimKarti(e)
                            }
                            .buttonStyle(PressButtonStyle())
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    store.draft.egitimler.removeAll { $0.id == e.id }
                                } label: { Label("Sil", systemImage: "trash") }
                            }
                        }
                        FAddButton(label: "Eğitim Ekle", ikon: "plus.circle.fill", renk: OzgecmisSection.egitim.renk) {
                            showTipSecimi = true
                        }
                        Color.clear.frame(height: 90)
                    }
                    .padding(.horizontal, FDS.hPad)
                }
            }
            .background(appTheme.backgroundMain.ignoresSafeArea())
            if let onDevamEt {
                FBottomBar(section: .egitim, renk: OzgecmisSection.egitim.renk) {
                    store.manuelKaydet()
                    onDevamEt()
                }
            }
        }
        .confirmationDialog("Eğitim türü seçin", isPresented: $showTipSecimi, titleVisibility: .visible) {
            Button("Lise")           { ekle("Lise") }
            Button("Önlisans")       { ekle("Önlisans") }
            Button("Lisans")         { ekle("Lisans") }
            Button("Yüksek Lisans")  { ekle("Yüksek Lisans") }
            Button("Doktora")        { ekle("Doktora") }
            Button("İptal", role: .cancel) {}
        }
        .fullScreenCover(item: $editorEgitim) { e in
            OzgecmisEgitimEditView(egitim: e, onCancel: { editorEgitim = nil }, onSave: { upd in
                if let i = store.draft.egitimler.firstIndex(where: { $0.id == upd.id }) {
                    store.draft.egitimler[i] = upd
                } else { store.draft.egitimler.append(upd) }
                editorEgitim = nil
            })
            .environmentObject(appTheme)
        }
    }

    private func ekle(_ derece: String) {
        var e = OzgecmisEgitim(); e.derece = derece; editorEgitim = e
    }

    private func egitimKarti(_ e: OzgecmisEgitim) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(OzgecmisSection.egitim.renk.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(OzgecmisSection.egitim.renk)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(e.okul.isEmpty ? (e.derece.isEmpty ? "Yeni Eğitim" : e.derece) : e.okul)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(appTheme.textPrimary)
                if !e.bolum.isEmpty {
                    Text(e.bolum).font(.system(size: 12)).foregroundColor(appTheme.textSecondary)
                }
                let tarih = [e.baslangic, e.bitis].filter { !$0.isEmpty }.joined(separator: " – ")
                if !tarih.isEmpty {
                    Text(tarih).font(.system(size: 11)).foregroundColor(appTheme.textSecondary.opacity(0.7))
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 11)).foregroundColor(appTheme.textSecondary.opacity(0.3))
        }
        .padding(14)
        .background(appTheme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(appTheme.cardStroke.opacity(0.35), lineWidth: 1))
        .shadow(color: .black.opacity(appTheme.isLight ? 0.04 : 0), radius: 8, y: 2)
    }
}

// Eğitim EditView — eski yapı korundu, ozgAyYilStr ile güncellendi
private struct OzgecmisEgitimEditView: View {
    @EnvironmentObject var appTheme: AppTheme
    @State private var form: OzgecmisEgitim
    @State private var showStart = false
    @State private var showEnd   = false
    @State private var startDate = Date()
    @State private var endDate   = Date()
    @State private var uniOnerileri: [String] = []
    @State private var gosterUni = false
    @State private var fakOnerileri: [String] = []
    @State private var gosterFak = false
    let onCancel: () -> Void
    let onSave: (OzgecmisEgitim) -> Void

    init(egitim: OzgecmisEgitim, onCancel: @escaping () -> Void, onSave: @escaping (OzgecmisEgitim) -> Void) {
        _form = State(initialValue: egitim); self.onCancel = onCancel; self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if form.derece.lowercased().contains("lise") {
                        FField(label: "Lise Adı", text: $form.okul, placeholder: "Örn: İstanbul Anadolu Lisesi")
                            .environmentObject(appTheme)
                        FDateButton(label: "Başlangıç (Ay/Yıl)", value: form.baslangic) { showStart = true }
                            .environmentObject(appTheme)
                        FDateButton(label: "Bitiş (Ay/Yıl)", value: form.bitis) { showEnd = true }
                            .environmentObject(appTheme)
                        DisclosureGroup {
                            VStack(spacing: 12) {
                                FField(label: "Lise Tipi", text: $form.liseTipi, placeholder: "Örn: Anadolu Lisesi")
                                    .environmentObject(appTheme)
                                FField(label: "Bölüm", text: $form.liseBolumu, placeholder: "Örn: Sayısal")
                                    .environmentObject(appTheme)
                            }.padding(.top, 6)
                } label: {
                            Text("Diğer Bilgiler").font(.system(size: 14, weight: .medium)).foregroundColor(appTheme.textSecondary)
                        }
                    } else {
                        FField(label: "Üniversite", text: $form.okul, placeholder: "Örn: Boğaziçi Üniversitesi")
            .environmentObject(appTheme)
                        FField(label: "Bölüm", text: $form.bolum, placeholder: "Örn: İşletme")
                            .environmentObject(appTheme)
                        FDateButton(label: "Başlangıç (Ay/Yıl)", value: form.baslangic) { showStart = true }
                            .environmentObject(appTheme)
                        FDateButton(label: "Bitiş (Ay/Yıl)", value: form.bitis) { showEnd = true }
                            .environmentObject(appTheme)
                        DisclosureGroup {
                            VStack(spacing: 12) {
                                FField(label: "Fakülte", text: $form.fakulte, placeholder: "Örn: İİBF")
                                    .environmentObject(appTheme)
                                FField(label: "Not Ortalaması", text: $form.notOrtalamasi, keyboard: .decimalPad, placeholder: "Örn: 3.20")
                                    .environmentObject(appTheme)
                                FField(label: "Öğretim Tipi", text: $form.ogretimTipi, placeholder: "Örgün / Uzaktan")
                                    .environmentObject(appTheme)
                                FField(label: "Burs Oranı", text: $form.bursOrani, placeholder: "Örn: %50")
                                    .environmentObject(appTheme)
                                FEditor(label: "Açıklama", text: $form.aciklama, minH: 100)
                                    .environmentObject(appTheme)
                            }.padding(.top, 6)
                        } label: {
                            Text("Diğer Bilgiler").font(.system(size: 14, weight: .medium)).foregroundColor(appTheme.textSecondary)
                        }
                    }
                }
                .padding(FDS.hPad)
            }
            .background(appTheme.backgroundMain.ignoresSafeArea())
            .navigationTitle("Eğitim")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Vazgeç", action: onCancel) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") { onSave(form) }.fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showStart) {
                MonthYearPickerView(title: "Başlangıç", date: $startDate, onDone: { d in
                    form.baslangic = ozgAyYilStr(from: d); showStart = false
                }, onCancel: { showStart = false }, theme: appTheme)
            }
            .sheet(isPresented: $showEnd) {
                MonthYearPickerView(title: "Bitiş", date: $endDate, onDone: { d in
                    form.bitis = ozgAyYilStr(from: d); showEnd = false
                }, onCancel: { showEnd = false }, theme: appTheme)
            }
            .onChange(of: form.okul) { _, v in
                uniOnerileri = UniversiteDataService.searchUniversiteler(query: v); gosterUni = !uniOnerileri.isEmpty
            }
            .onChange(of: form.fakulte) { _, v in
                fakOnerileri = FakulteDataService.searchFakulteler(query: v); gosterFak = !fakOnerileri.isEmpty
            }
        }
    }
}

// MARK: ═══════════════════════════════════════════════════════
// MARK: 5. YETENEKLER
// ═══════════════════════════════════════════════════════════
struct OzgecmisYeteneklerFormView: View {
    @EnvironmentObject var appTheme: AppTheme
    @EnvironmentObject var store: OzgecmisStore
    var onDevamEt: (() -> Void)? = nil
    @State private var yeni = ""

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    FSectionProgress(current: bolumIndex(.yetenekler), total: sectionSirasi.count, renk: OzgecmisSection.yetenekler.renk)
                    VStack(alignment: .leading, spacing: 16) {
                        Color.clear.frame(height: 8)
                Text("Virgül veya Enter ile ayırarak yetenek ekleyebilirsiniz.")
                            .font(.system(size: 12))
                    .foregroundColor(appTheme.textSecondary)
                HStack(spacing: 10) {
                    TextField("Örn. Swift, Excel, Liderlik", text: $yeni)
                        .textFieldStyle(.plain)
                                .font(.system(size: 15))
                        .foregroundColor(appTheme.textPrimary)
                                .padding(.horizontal, 14)
                                .frame(height: FDS.fieldH)
                                .background(FDS.cardBG)
                                .clipShape(RoundedRectangle(cornerRadius: FDS.radius, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: FDS.radius, style: .continuous)
                                    .stroke(appTheme.cardStroke.opacity(0.5), lineWidth: 1))
                        .onSubmit { ekle() }
                    Button { ekle() } label: {
                        Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(OzgecmisSection.yetenekler.renk)
                    }
                }
                FlowLayoutOzg(spacing: 8) {
                            ForEach(Array(store.draft.yetenekler.enumerated()), id: \.offset) { idx, y in
                                HStack(spacing: 5) {
                                    Text(y).font(.system(size: 13, weight: .medium)).foregroundColor(appTheme.textPrimary)
                                    Button { store.draft.yetenekler.remove(at: idx) } label: {
                                Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 14))
                                    .foregroundColor(appTheme.textSecondary)
                            }
                        }
                                .padding(.horizontal, 12).padding(.vertical, 7)
                                .background(OzgecmisSection.yetenekler.renk.opacity(0.10))
                        .clipShape(Capsule())
                                .overlay(Capsule().stroke(OzgecmisSection.yetenekler.renk.opacity(0.20), lineWidth: 1))
                            }
                        }
                        Color.clear.frame(height: 90)
                    }
                    .padding(.horizontal, FDS.hPad)
                }
            }
            .background(appTheme.backgroundMain.ignoresSafeArea())
            if let onDevamEt {
                FBottomBar(section: .yetenekler, renk: OzgecmisSection.yetenekler.renk) {
                    store.manuelKaydet()
                    onDevamEt()
                }
            }
        }
    }
    private func ekle() {
        let p = yeni.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        for s in p where !store.draft.yetenekler.contains(s) { store.draft.yetenekler.append(s) }
        if !p.isEmpty { yeni = "" }
    }
}

// MARK: ═══════════════════════════════════════════════════════
// MARK: 6. DİLLER — Chip satırı + kayıt göstergesi (Madde 5)
// ═══════════════════════════════════════════════════════════
struct OzgecmisDillerFormView: View {
    @EnvironmentObject var appTheme: AppTheme
    @EnvironmentObject var store: OzgecmisStore
    var onDevamEt: (() -> Void)? = nil
    @State private var editID: UUID? = nil
    @State private var yeniDil = OzgecmisDil()
    @State private var showEditor = false
    @State private var kayitliFlash = false

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    FSectionProgress(current: bolumIndex(.diller), total: sectionSirasi.count, renk: OzgecmisSection.diller.renk)
            VStack(alignment: .leading, spacing: 16) {
                        Color.clear.frame(height: 8)

                        // Chip satırı — eklenen diller (Madde 5)
                        if !store.draft.diller.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.green)
                                    Text("Kaydedilen Diller")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(appTheme.textSecondary)
                                }
                                .opacity(kayitliFlash ? 1 : 0.6)
                                .animation(.easeInOut(duration: 0.4), value: kayitliFlash)

                                FlowLayoutOzg(spacing: 8) {
                ForEach(store.draft.diller) { d in
                                        Button { editID = d.id; showEditor = true } label: {
                                            HStack(spacing: 6) {
                                                Circle()
                                                    .fill(Color.green)
                                                    .frame(width: 6, height: 6)
                                                Text(d.dilAdi.isEmpty ? "Dil" : d.dilAdi)
                                                    .font(.system(size: 12, weight: .medium))
                                                    .foregroundColor(OzgecmisSection.diller.renk)
                                                if !d.seviye.isEmpty {
                                                    Text("· \(d.seviye)")
                                                        .font(.system(size: 11))
                                                        .foregroundColor(appTheme.textSecondary)
                                                }
                                                Image(systemName: "pencil")
                                                    .font(.system(size: 9))
                                                    .foregroundColor(appTheme.textSecondary.opacity(0.5))
                                            }
                                            .padding(.horizontal, 10).padding(.vertical, 6)
                                            .background(OzgecmisSection.diller.renk.opacity(0.09))
                                            .clipShape(Capsule())
                                            .overlay(Capsule().stroke(OzgecmisSection.diller.renk.opacity(0.25), lineWidth: 1))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .padding(12)
                            .background(Color.green.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.green.opacity(0.20), lineWidth: 1))
                        }

                        // Yeni dil formu
                        dilEditorView(dil: editID.flatMap { id in store.draft.diller.first { $0.id == id } } ?? yeniDil)

                        Color.clear.frame(height: 90)
                    }
                    .padding(.horizontal, FDS.hPad)
                }
            }
            .background(appTheme.backgroundMain.ignoresSafeArea())

            if let onDevamEt {
                FBottomBar(section: .diller, renk: OzgecmisSection.diller.renk) {
                    // Dili kaydet + flash göster
                    kaydetDil()
                    store.manuelKaydet()
                    withAnimation { kayitliFlash = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation { kayitliFlash = false }
                    }
                    onDevamEt()
                }
            }
        }
    }

    private func dilEditorView(dil: OzgecmisDil) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            FLabel(text: editID == nil ? "Yeni Dil Ekle" : "Dili Düzenle")

            FField(label: "Dil Adı", text: dilNameBinding, placeholder: "Örn: İngilizce")

            FField(label: "Seviye", text: dilSeviyeBinding, placeholder: "B2, C1, Anadil…")

            VStack(alignment: .leading, spacing: 8) {
                FLabel(text: "Yıldız Seviyesi (isteğe bağlı)")
                HStack(spacing: 10) {
                    ForEach(1...5, id: \.self) { s in
                        Button {
                            let cur = dilYildizBinding.wrappedValue
                            dilYildizBinding.wrappedValue = cur == s ? nil : s
                                    } label: {
                            Image(systemName: s <= (dilYildizBinding.wrappedValue ?? 0) ? "star.fill" : "star")
                                .font(.system(size: 22))
                                .foregroundColor(s <= (dilYildizBinding.wrappedValue ?? 0)
                                    ? OzgecmisSection.diller.renk : appTheme.cardStroke)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
            if editID != nil {
                            Button(role: .destructive) {
                    if let id = editID {
                        store.draft.diller.removeAll { $0.id == id }
                        editID = nil
                    }
                            } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                        Text("Bu dili sil")
                            }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.red)
                        }
                .buttonStyle(.plain)
                    }
        }
        .padding(14)
                    .background(appTheme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(appTheme.cardStroke.opacity(0.35), lineWidth: 1))
    }

    // Binding yardımcıları
    private var dilNameBinding: Binding<String> {
        if let id = editID {
            return Binding(
                get: { store.draft.diller.first { $0.id == id }?.dilAdi ?? "" },
                set: { v in if let i = store.draft.diller.firstIndex(where: { $0.id == id }) { store.draft.diller[i].dilAdi = v } }
            )
        }
        return Binding(get: { yeniDil.dilAdi }, set: { yeniDil.dilAdi = $0 })
    }
    private var dilSeviyeBinding: Binding<String> {
        if let id = editID {
            return Binding(
                get: { store.draft.diller.first { $0.id == id }?.seviye ?? "" },
                set: { v in if let i = store.draft.diller.firstIndex(where: { $0.id == id }) { store.draft.diller[i].seviye = v } }
            )
        }
        return Binding(get: { yeniDil.seviye }, set: { yeniDil.seviye = $0 })
    }
    private var dilYildizBinding: Binding<Int?> {
        if let id = editID {
            return Binding(
                get: { store.draft.diller.first { $0.id == id }?.yildizSeviye },
                set: { v in if let i = store.draft.diller.firstIndex(where: { $0.id == id }) { store.draft.diller[i].yildizSeviye = v } }
            )
        }
        return Binding(get: { yeniDil.yildizSeviye }, set: { yeniDil.yildizSeviye = $0 })
    }

    private func kaydetDil() {
        if let id = editID {
            // Düzenleme zaten binding üzerinden yapıldı
            _ = id
            editID = nil
        } else {
            let ad = yeniDil.dilAdi.trimmingCharacters(in: .whitespaces)
            guard !ad.isEmpty else { return }
            store.draft.diller.append(yeniDil)
            yeniDil = OzgecmisDil()
        }
    }
}

// MARK: ═══════════════════════════════════════════════════════
// MARK: 7. SERTİFİKALAR
// ═══════════════════════════════════════════════════════════
struct OzgecmisSertifikalarFormView: View {
    @EnvironmentObject var appTheme: AppTheme
    @EnvironmentObject var store: OzgecmisStore
    var onDevamEt: (() -> Void)? = nil
    @State private var editorSertifika: OzgecmisSertifika?

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    FSectionProgress(current: bolumIndex(.sertifikalar), total: sectionSirasi.count, renk: OzgecmisSection.sertifikalar.renk)
                    VStack(spacing: 14) {
                        Color.clear.frame(height: 8)
                    ForEach(store.draft.sertifikalar) { s in
                            Button { editorSertifika = s } label: {
                                sertKarti(s)
                            }
                            .buttonStyle(PressButtonStyle())
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) { store.draft.sertifikalar.removeAll { $0.id == s.id } } label: {
                                    Label("Sil", systemImage: "trash")
                                }
                            }
                        }
                        FAddButton(label: "Sertifika / Kurs Ekle", ikon: "plus.circle.fill", renk: OzgecmisSection.sertifikalar.renk) {
                    editorSertifika = OzgecmisSertifika()
                        }
                        Color.clear.frame(height: 90)
                    }
                    .padding(.horizontal, FDS.hPad)
                }
            }
            .background(appTheme.backgroundMain.ignoresSafeArea())
            if let onDevamEt {
                FBottomBar(section: .sertifikalar, renk: OzgecmisSection.sertifikalar.renk) {
                    store.manuelKaydet()
                    onDevamEt()
                }
            }
        }
        .fullScreenCover(item: $editorSertifika) { s in
            OzgecmisSertifikaEditView(sertifika: s, onCancel: { editorSertifika = nil }, onSave: { upd in
                if let i = store.draft.sertifikalar.firstIndex(where: { $0.id == upd.id }) {
                    store.draft.sertifikalar[i] = upd
                } else { store.draft.sertifikalar.append(upd) }
                editorSertifika = nil
            })
            .environmentObject(appTheme)
        }
    }

    private func sertKarti(_ s: OzgecmisSertifika) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(OzgecmisSection.sertifikalar.renk.opacity(0.12)).frame(width: 44, height: 44)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 16, weight: .semibold)).foregroundColor(OzgecmisSection.sertifikalar.renk)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(s.ad.isEmpty ? "Sertifika" : s.ad)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(appTheme.textPrimary)
                if !s.verenKurum.isEmpty {
                    Text(s.verenKurum)
                        .font(.system(size: 12))
                        .foregroundColor(appTheme.textSecondary)
                }
                if !s.tarih.isEmpty {
                    Text(s.tarih)
                        .font(.system(size: 11))
                        .foregroundColor(appTheme.textSecondary.opacity(0.7))
                }
                if !s.aciklama.isEmpty {
                    Text(s.aciklama)
                        .font(.system(size: 11))
                        .foregroundColor(appTheme.textSecondary)
                    .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 11)).foregroundColor(appTheme.textSecondary.opacity(0.3))
        }
        .padding(14).background(appTheme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(appTheme.cardStroke.opacity(0.35), lineWidth: 1))
        .shadow(color: .black.opacity(appTheme.isLight ? 0.04 : 0), radius: 8, y: 2)
    }
}

private struct OzgecmisSertifikaEditView: View {
    @EnvironmentObject var appTheme: AppTheme
    @State private var form: OzgecmisSertifika
    let onCancel: () -> Void
    let onSave: (OzgecmisSertifika) -> Void
    init(sertifika: OzgecmisSertifika, onCancel: @escaping () -> Void, onSave: @escaping (OzgecmisSertifika) -> Void) {
        _form = State(initialValue: sertifika); self.onCancel = onCancel; self.onSave = onSave
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    FField(label: "Sertifika Adı", text: $form.ad).environmentObject(appTheme)
                    FField(label: "Veren Kurum", text: $form.verenKurum).environmentObject(appTheme)
                    FField(label: "Tarih", text: $form.tarih, placeholder: "Örn: 2023 veya Mart 2023").environmentObject(appTheme)
                    FEditor(label: "Açıklama", text: $form.aciklama, minH: 100).environmentObject(appTheme)
                }.padding(FDS.hPad)
            }
            .background(appTheme.backgroundMain.ignoresSafeArea())
            .navigationTitle("Sertifika / Kurs").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Vazgeç", action: onCancel) }
                ToolbarItem(placement: .confirmationAction) { Button("Kaydet") { onSave(form) }.fontWeight(.semibold) }
            }
        }
    }
}

// MARK: ═══════════════════════════════════════════════════════
// MARK: 8. PROJELER
// ═══════════════════════════════════════════════════════════
struct OzgecmisProjelerFormView: View {
    @EnvironmentObject var appTheme: AppTheme
    @EnvironmentObject var store: OzgecmisStore
    var onDevamEt: (() -> Void)? = nil
    @State private var editorProje: OzgecmisProje?

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    FSectionProgress(current: bolumIndex(.projeler), total: sectionSirasi.count, renk: OzgecmisSection.projeler.renk)
                    VStack(spacing: 14) {
                        Color.clear.frame(height: 8)
                    ForEach(store.draft.projeler) { p in
                            Button { editorProje = p } label: { projeKarti(p) }
                                .buttonStyle(PressButtonStyle())
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) { store.draft.projeler.removeAll { $0.id == p.id } } label: {
                                        Label("Sil", systemImage: "trash")
                                    }
                                }
                        }
                        FAddButton(label: "Proje Ekle", ikon: "plus.circle.fill", renk: OzgecmisSection.projeler.renk) {
                    editorProje = OzgecmisProje()
                        }
                        Color.clear.frame(height: 90)
                    }
                    .padding(.horizontal, FDS.hPad)
                }
            }
            .background(appTheme.backgroundMain.ignoresSafeArea())
            if let onDevamEt {
                FBottomBar(section: .projeler, renk: OzgecmisSection.projeler.renk) {
                    store.manuelKaydet()
                    onDevamEt()
                }
            }
        }
        .fullScreenCover(item: $editorProje) { p in
            OzgecmisProjeEditView(proje: p, onCancel: { editorProje = nil }, onSave: { upd in
                if let i = store.draft.projeler.firstIndex(where: { $0.id == upd.id }) { store.draft.projeler[i] = upd }
                else { store.draft.projeler.append(upd) }
                    editorProje = nil
            }).environmentObject(appTheme)
        }
    }
    private func projeKarti(_ p: OzgecmisProje) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(OzgecmisSection.projeler.renk.opacity(0.12)).frame(width: 44, height: 44)
                Image(systemName: "folder.fill")
                    .font(.system(size: 16, weight: .semibold)).foregroundColor(OzgecmisSection.projeler.renk)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(p.projeAdi.isEmpty ? "Proje" : p.projeAdi).font(.system(size: 14, weight: .semibold)).foregroundColor(appTheme.textPrimary)
                if !p.tarih.isEmpty { Text(p.tarih).font(.system(size: 11)).foregroundColor(appTheme.textSecondary) }
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 11)).foregroundColor(appTheme.textSecondary.opacity(0.3))
        }
        .padding(14).background(appTheme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(appTheme.cardStroke.opacity(0.35), lineWidth: 1))
        .shadow(color: .black.opacity(appTheme.isLight ? 0.04 : 0), radius: 8, y: 2)
    }
}

private struct OzgecmisProjeEditView: View {
    @EnvironmentObject var appTheme: AppTheme
    @State private var form: OzgecmisProje
    let onCancel: () -> Void; let onSave: (OzgecmisProje) -> Void
    init(proje: OzgecmisProje, onCancel: @escaping () -> Void, onSave: @escaping (OzgecmisProje) -> Void) {
        _form = State(initialValue: proje); self.onCancel = onCancel; self.onSave = onSave
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    FField(label: "Proje Adı", text: $form.projeAdi).environmentObject(appTheme)
                    FEditor(label: "Açıklama", text: $form.aciklama, minH: 120).environmentObject(appTheme)
                    FField(label: "Tarih / Süre", text: $form.tarih, placeholder: "Örn: 2023 veya 3 ay").environmentObject(appTheme)
                    FField(label: "Link", text: $form.link, keyboard: .URL, autocap: .never).environmentObject(appTheme)
                }.padding(FDS.hPad)
            }
            .background(appTheme.backgroundMain.ignoresSafeArea())
            .navigationTitle("Proje").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Vazgeç", action: onCancel) }
                ToolbarItem(placement: .confirmationAction) { Button("Kaydet") { onSave(form) }.fontWeight(.semibold) }
            }
        }
    }
}

// MARK: ═══════════════════════════════════════════════════════
// MARK: 9. REFERANSLAR
// ═══════════════════════════════════════════════════════════
struct OzgecmisReferanslarFormView: View {
    @EnvironmentObject var appTheme: AppTheme
    @EnvironmentObject var store: OzgecmisStore
    var onDevamEt: (() -> Void)? = nil
    @State private var editorReferans: OzgecmisReferans?

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    FSectionProgress(current: bolumIndex(.referanslar), total: sectionSirasi.count, renk: OzgecmisSection.referanslar.renk)
                    VStack(spacing: 14) {
                        Color.clear.frame(height: 8)
                    ForEach(store.draft.referanslar) { r in
                            Button { editorReferans = r } label: { refKarti(r) }
                                .buttonStyle(PressButtonStyle())
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) { store.draft.referanslar.removeAll { $0.id == r.id } } label: {
                                        Label("Sil", systemImage: "trash")
                                    }
                                }
                        }
                        FAddButton(label: "Referans Ekle", ikon: "plus.circle.fill", renk: OzgecmisSection.referanslar.renk) {
                    editorReferans = OzgecmisReferans()
                        }
                        Color.clear.frame(height: 90)
                    }
                    .padding(.horizontal, FDS.hPad)
                }
            }
            .background(appTheme.backgroundMain.ignoresSafeArea())
            if let onDevamEt {
                FBottomBar(section: .referanslar, renk: OzgecmisSection.referanslar.renk) {
                    store.manuelKaydet()
                    onDevamEt()
                }
            }
        }
        .fullScreenCover(item: $editorReferans) { r in
            OzgecmisReferansEditView(referans: r, onCancel: { editorReferans = nil }, onSave: { upd in
                if let i = store.draft.referanslar.firstIndex(where: { $0.id == upd.id }) { store.draft.referanslar[i] = upd }
                else { store.draft.referanslar.append(upd) }
                    editorReferans = nil
            }).environmentObject(appTheme)
        }
    }
    private func refKarti(_ r: OzgecmisReferans) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(OzgecmisSection.referanslar.renk.opacity(0.12)).frame(width: 44, height: 44)
                Image(systemName: "person.2.fill")
                    .font(.system(size: 16, weight: .semibold)).foregroundColor(OzgecmisSection.referanslar.renk)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(r.adSoyad.isEmpty ? "Referans" : r.adSoyad).font(.system(size: 14, weight: .semibold)).foregroundColor(appTheme.textPrimary)
                let alt = [r.unvan, r.firma].filter { !$0.isEmpty }.joined(separator: " · ")
                if !alt.isEmpty { Text(alt).font(.system(size: 12)).foregroundColor(appTheme.textSecondary) }
            }
                Spacer()
            Image(systemName: "chevron.right").font(.system(size: 11)).foregroundColor(appTheme.textSecondary.opacity(0.3))
        }
        .padding(14).background(appTheme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(appTheme.cardStroke.opacity(0.35), lineWidth: 1))
        .shadow(color: .black.opacity(appTheme.isLight ? 0.04 : 0), radius: 8, y: 2)
    }
}

private struct OzgecmisReferansEditView: View {
    @EnvironmentObject var appTheme: AppTheme
    @State private var form: OzgecmisReferans
    let onCancel: () -> Void; let onSave: (OzgecmisReferans) -> Void
    init(referans: OzgecmisReferans, onCancel: @escaping () -> Void, onSave: @escaping (OzgecmisReferans) -> Void) {
        _form = State(initialValue: referans); self.onCancel = onCancel; self.onSave = onSave
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    FField(label: "Ad Soyad", text: $form.adSoyad, autocap: .words).environmentObject(appTheme)
                    FField(label: "Unvan", text: $form.unvan).environmentObject(appTheme)
                    FField(label: "Firma", text: $form.firma).environmentObject(appTheme)
                    FField(label: "Telefon", text: $form.telefon, keyboard: .phonePad).environmentObject(appTheme)
                    FField(label: "E-posta", text: $form.email, keyboard: .emailAddress, autocap: .never).environmentObject(appTheme)
                }.padding(FDS.hPad)
            }
            .background(appTheme.backgroundMain.ignoresSafeArea())
            .navigationTitle("Referans").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Vazgeç", action: onCancel) }
                ToolbarItem(placement: .confirmationAction) { Button("Kaydet") { onSave(form) }.fontWeight(.semibold) }
            }
        }
    }
}

// MARK: ═══════════════════════════════════════════════════════
// MARK: 10. DİĞER (Ödüller, Hobiler, Ek)
// ═══════════════════════════════════════════════════════════
struct OzgecmisDigerFormView: View {
    @EnvironmentObject var appTheme: AppTheme
    @EnvironmentObject var store: OzgecmisStore
    var onDevamEt: (() -> Void)? = nil
    @State private var yeniOdul = ""
    @State private var yeniHobi = ""

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    FSectionProgress(current: bolumIndex(.diger), total: sectionSirasi.count, renk: OzgecmisSection.diger.renk)
            VStack(alignment: .leading, spacing: 24) {
                        Color.clear.frame(height: 8)
                        chipGiris("Ödüller / Başarılar", placeholder: "Ödül ekle", yeni: $yeniOdul, liste: $store.draft.oduller, renk: OzgecmisSection.diger.renk)
                        chipGiris("Hobiler / İlgi Alanları", placeholder: "Hobi ekle", yeni: $yeniHobi, liste: $store.draft.hobiler, renk: OzgecmisSection.diger.renk)
                        FEditor(label: "Ek Bilgiler", text: $store.draft.ekBilgiler, minH: 100)
                        Color.clear.frame(height: 90)
                    }
                    .padding(.horizontal, FDS.hPad)
                }
            }
            .background(appTheme.backgroundMain.ignoresSafeArea())
            if let onDevamEt {
                FBottomBar(section: .diger, renk: OzgecmisSection.diger.renk) {
                    store.manuelKaydet()
                    onDevamEt()
                }
            }
        }
    }

    private func chipGiris(_ baslik: String, placeholder: String, yeni: Binding<String>, liste: Binding<[String]>, renk: Color) -> some View {
                VStack(alignment: .leading, spacing: 10) {
            Text(baslik).font(.system(size: 15, weight: .semibold)).foregroundColor(appTheme.textPrimary)
                    HStack(spacing: 10) {
                TextField(placeholder, text: yeni)
                    .textFieldStyle(.plain).font(.system(size: 15)).foregroundColor(appTheme.textPrimary)
                    .padding(.horizontal, 14).frame(height: FDS.fieldH)
                    .background(FDS.cardBG)
                    .clipShape(RoundedRectangle(cornerRadius: FDS.radius, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: FDS.radius, style: .continuous).stroke(appTheme.cardStroke.opacity(0.5), lineWidth: 1))
                    .onSubmit { let v = yeni.wrappedValue.trimmingCharacters(in: .whitespaces); if !v.isEmpty { liste.wrappedValue.append(v); yeni.wrappedValue = "" } }
                Button {
                    let v = yeni.wrappedValue.trimmingCharacters(in: .whitespaces)
                    if !v.isEmpty { liste.wrappedValue.append(v); yeni.wrappedValue = "" }
                } label: { Image(systemName: "plus.circle.fill").font(.system(size: 28)).foregroundColor(renk) }
                    }
                    FlowLayoutOzg(spacing: 8) {
                ForEach(Array(liste.wrappedValue.enumerated()), id: \.offset) { idx, item in
                    HStack(spacing: 5) {
                        Text(item).font(.system(size: 13, weight: .medium)).foregroundColor(appTheme.textPrimary)
                        Button { liste.wrappedValue.remove(at: idx) } label: {
                            Image(systemName: "xmark.circle.fill").font(.system(size: 14)).foregroundColor(appTheme.textSecondary)
                        }
                    }
                    .padding(.horizontal, 12).padding(.vertical, 7)
                    .background(renk.opacity(0.10)).clipShape(Capsule())
                    .overlay(Capsule().stroke(renk.opacity(0.20), lineWidth: 1))
                }
            }
        }
    }
}

// MARK: - Ortak Picker'lar (değişmedi, sadece ozgAyYilStr ile güncellendi)
private struct MonthYearPickerView: View {
    let title: String
    @Binding var date: Date
    let onDone: (Date) -> Void
    let onCancel: () -> Void
    let theme: AppTheme
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date()) - 1
    @State private var selectedYear:  Int = Calendar.current.component(.year, from: Date())
    private let months = Calendar.current.monthSymbols
    private let years: [Int] = { let c = Calendar.current.component(.year, from: Date()); return Array((c - 40)...(c + 10)) }()

    var body: some View {
        NavigationStack {
                                HStack {
                Picker("Ay", selection: $selectedMonth) {
                    ForEach(0..<months.count, id: \.self) { Text(months[$0]).tag($0) }
                }.pickerStyle(.wheel)
                Picker("Yıl", selection: $selectedYear) {
                    // Tag olarak Int kullan — Text("\(year)") Locale binlik ayraç koyabilir,
                    // ama Picker etiket sadece görsel; seçim Int.
                    ForEach(years, id: \.self) { year in
                        Text(String(year)).tag(year)  // String(year) → Locale bağımsız
                    }
                }.pickerStyle(.wheel)
            }.padding()
            .background(theme.background.ignoresSafeArea())
            .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") { onCancel(); dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Tamam") {
                        var c = DateComponents(); c.year = selectedYear; c.month = selectedMonth + 1; c.day = 1
                        let d = Calendar.current.date(from: c) ?? date
                        onDone(d); dismiss()
                    }.fontWeight(.semibold)
                }
            }
            .onAppear {
                let cal = Calendar.current
                selectedMonth = max(0, min(months.count - 1, cal.component(.month, from: date) - 1))
                let y = cal.component(.year, from: date)
                selectedYear = max(years.first ?? y, min(years.last ?? y, y))
            }
        }
    }
}

private struct MonthYearFuturePickerView: View {
    let title: String
    @Binding var date: Date
    let onDone: (Date) -> Void
    let onCancel: () -> Void
    let theme: AppTheme
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date()) - 1
    @State private var selectedYear:  Int = Calendar.current.component(.year, from: Date())
    private let months = Calendar.current.monthSymbols
    private let years: [Int] = { let c = Calendar.current.component(.year, from: Date()); return Array(c...(c + 40)) }()

    var body: some View {
        NavigationStack {
                                HStack {
                Picker("Ay", selection: $selectedMonth) {
                    ForEach(0..<months.count, id: \.self) { Text(months[$0]).tag($0) }
                }.pickerStyle(.wheel)
                Picker("Yıl", selection: $selectedYear) {
                    ForEach(years, id: \.self) { Text(String($0)).tag($0) }
                }.pickerStyle(.wheel)
            }.padding()
            .background(theme.background.ignoresSafeArea())
            .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") { onCancel(); dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Tamam") {
                        var c = DateComponents(); c.year = selectedYear; c.month = selectedMonth + 1; c.day = 1
                        let d = Calendar.current.date(from: c) ?? date
                        onDone(d); dismiss()
                    }.fontWeight(.semibold)
                }
            }
            .onAppear {
                let cal = Calendar.current
                selectedMonth = max(0, min(months.count - 1, cal.component(.month, from: date) - 1))
                let y = cal.component(.year, from: date)
                selectedYear = max(years.first ?? y, min(years.last ?? y, y))
            }
        }
    }
}

// MARK: - FlowLayout (değişmedi)
private struct FlowLayoutOzg: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        lay(proposal: proposal, subviews: subviews).size
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for (i, p) in lay(proposal: proposal, subviews: subviews).positions.enumerated() {
            subviews[i].place(at: CGPoint(x: bounds.minX + p.x, y: bounds.minY + p.y), proposal: .unspecified)
        }
    }
    private func lay(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxW = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0, pts: [CGPoint] = []
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x + sz.width > maxW && x > 0 { x = 0; y += rowH + spacing; rowH = 0 }
            pts.append(CGPoint(x: x, y: y)); rowH = max(rowH, sz.height); x += sz.width + spacing
        }
        return (CGSize(width: maxW, height: y + rowH), pts)
    }
}

// MARK: - Profil fotoğrafı seçici (değişmedi)
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let p = UIImagePickerController()
        p.delegate = context.coordinator
        // Sistem kare kırpmayı KAPAT: tek adım yuvarlak kırpma CircularPhotoCropView'da
        p.allowsEditing = false
        p.sourceType = .photoLibrary
        return p
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.image = info[.originalImage] as? UIImage
            parent.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
    }
}

// MARK: - JustifiedTextView (değişmedi — orijinalden alındı)
private struct JustifiedTextView: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    @Binding var dynamicHeight: CGFloat
    let foregroundColor: UIColor
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    static func justifiedAttrs(color: UIColor) -> [NSAttributedString.Key: Any] {
        let para = NSMutableParagraphStyle(); para.alignment = .justified
        return [.font: UIFont.systemFont(ofSize: 17), .foregroundColor: color, .paragraphStyle: para]
    }
    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView(); tv.isScrollEnabled = false; tv.backgroundColor = .clear
        tv.autocorrectionType = .default; tv.autocapitalizationType = .sentences
        tv.delegate = context.coordinator
        tv.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        tv.typingAttributes = Self.justifiedAttrs(color: foregroundColor)
        let bar = UIToolbar(); bar.sizeToFit()
        bar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "Bitti", style: .done, target: context.coordinator, action: #selector(Coordinator.dismiss))
        ]
        tv.inputAccessoryView = bar; return tv
    }
    func updateUIView(_ tv: UITextView, context: Context) {
        if tv.text != text {
            let sel = tv.selectedRange
            tv.attributedText = NSAttributedString(string: text, attributes: Self.justifiedAttrs(color: foregroundColor))
            let safeLoc = min(sel.location, (text as NSString).length)
            tv.selectedRange = NSRange(location: safeLoc, length: 0)
        }
        tv.typingAttributes = Self.justifiedAttrs(color: foregroundColor)
        Self.recalc(tv: tv, binding: $dynamicHeight)
    }
    static func recalc(tv: UITextView, binding: Binding<CGFloat>) {
        let size = tv.sizeThatFits(CGSize(width: tv.bounds.width > 0 ? tv.bounds.width : 300, height: .infinity))
        DispatchQueue.main.async { if abs(binding.wrappedValue - size.height) > 1 { binding.wrappedValue = size.height } }
    }
    class Coordinator: NSObject, UITextViewDelegate {
        var p: JustifiedTextView; init(_ p: JustifiedTextView) { self.p = p }
        func textViewDidChange(_ tv: UITextView) {
            let attrs = JustifiedTextView.justifiedAttrs(color: p.foregroundColor)
            let sel = tv.selectedRange
            let m = NSMutableAttributedString(string: tv.text)
            m.addAttributes(attrs, range: NSRange(location: 0, length: m.length))
            tv.attributedText = m; tv.selectedRange = sel; tv.typingAttributes = attrs
            p.text = tv.text; JustifiedTextView.recalc(tv: tv, binding: p.$dynamicHeight)
        }
        func textViewDidBeginEditing(_ tv: UITextView) {
            tv.typingAttributes = JustifiedTextView.justifiedAttrs(color: p.foregroundColor)
            DispatchQueue.main.async { self.p.isFocused = true }
        }
        func textViewDidEndEditing(_ tv: UITextView) { DispatchQueue.main.async { self.p.isFocused = false } }
        @objc func dismiss() { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
    }
}

// MARK: - CV ATS Puanlama
struct CVATSPuanlamaView: View {
    @EnvironmentObject var appTheme: AppTheme
    @EnvironmentObject var store: OzgecmisStore
    @Environment(\.dismiss) private var dismiss

    @State private var skor: Int?
    @State private var genelYorum = ""
    @State private var gucluYonler: [String] = []
    @State private var iyilestirmeler: [String] = []
    @State private var yukleniyor = false
    @State private var hata: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if yukleniyor {
                        ProgressView("CV analiz ediliyor...")
                            .padding(.top, 40)
                    } else if let s = skor {
                        Text("\(s) / 100")
                            .font(.system(size: 36, weight: .heavy, design: .rounded))
                            .foregroundColor(s >= 70 ? Color(hex: "10B981") : Color(hex: "F59E0B"))
                        if !genelYorum.isEmpty {
                            Text(genelYorum)
                                .font(.system(size: 14))
                                .foregroundColor(appTheme.textSecondary)
                        }
                        if !gucluYonler.isEmpty {
                            bolum("Guclu Yonler", items: gucluYonler, color: Color(hex: "10B981"))
                        }
                        if !iyilestirmeler.isEmpty {
                            bolum("Iyilestirme Onerileri", items: iyilestirmeler, color: Color(hex: "F59E0B"))
                        }
                    } else if let h = hata {
                        Text(h).foregroundColor(appTheme.textSecondary)
                    } else {
                        Button {
                            Task { await puanla() }
                        } label: {
                            Label("CV'mi Puanla", systemImage: "checkmark.shield.fill")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color(hex: "3B82F6"))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(PressButtonStyle())
                    }
                }
                .padding(20)
            }
            .background(appTheme.backgroundMain.ignoresSafeArea())
            .navigationTitle("CV Puanlama")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }

    private func bolum(_ title: String, items: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(appTheme.textPrimary)
            ForEach(items, id: \.self) { t in
                HStack(alignment: .top, spacing: 8) {
                    Circle().fill(color).frame(width: 6, height: 6).padding(.top, 6)
                    Text(t).font(.system(size: 13)).foregroundColor(appTheme.textSecondary)
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(appTheme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func puanla() async {
        yukleniyor = true
        defer { yukleniyor = false }
        hata = nil

        let d = store.draft
        let cvOzet = """
        Ad: \(d.kisisel.adSoyad)
        Ozet: \(d.ozet)
        Deneyim: \(d.isDeneyimleri.count)
        Egitim: \(d.egitimler.count)
        Yetenekler: \(d.yetenekler.joined(separator: ", "))
        """

        do {
            let url = URL(string: "https://api.openai.com/v1/chat/completions")!
            var request = OpenAIService.shared.makeRequest(url: url)
            let prompt = """
            CV icin ATS puani ver. Sadece JSON don:
            {"skor": 0, "genelYorum": "", "gucluYonler": [], "iyilestirmeler": []}
            """
            let body: [String: Any] = [
                "model": "gpt-4o-mini",
                "messages": [
                    ["role": "system", "content": prompt],
                    ["role": "user", "content": cvOzet],
                ],
                "temperature": 0.3,
                "max_tokens": 500,
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { throw URLError(.badServerResponse) }
            let raw = try JSONDecoder().decode(OpenAIResponse.self, from: data).choices.first?.message.content ?? "{}"
            let temiz = raw.replacingOccurrences(of: "```json", with: "").replacingOccurrences(of: "```", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            struct S: Codable { let skor: Int; let genelYorum: String; let gucluYonler: [String]; let iyilestirmeler: [String] }
            let s = try JSONDecoder().decode(S.self, from: Data(temiz.utf8))
            skor = s.skor
            genelYorum = s.genelYorum
            gucluYonler = s.gucluYonler
            iyilestirmeler = s.iyilestirmeler
        } catch {
            hata = "Analiz yapilamadi. Baglantini kontrol edip tekrar dene."
        }
    }
}

// MARK: - AI Profesyonel Ozet
struct AIProfesyonelOzetButton: View {
    @EnvironmentObject var appTheme: AppTheme
    @EnvironmentObject var store: OzgecmisStore
    @State private var yukleniyor = false

    var body: some View {
        Button {
            Task { await ozetUret() }
        } label: {
            HStack(spacing: 10) {
                if yukleniyor {
                    ProgressView().tint(.white).scaleEffect(0.8)
                } else {
                    Image(systemName: "sparkles")
                }
                Text(yukleniyor ? "Ozet hazirlaniyor..." : "AI ile Ozet Olustur")
                    .font(.system(size: 14, weight: .bold))
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .frame(height: 46)
            .background(
                LinearGradient(colors: [Color(hex: "8B5CF6"), Color(hex: "6D28D9")], startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(PressButtonStyle())
        .disabled(yukleniyor)
    }

    private func ozetUret() async {
        yukleniyor = true
        defer { yukleniyor = false }
        let d = store.draft
        let userPrompt = """
        Is deneyimleri: \(d.isDeneyimleri.map { "\($0.unvan) - \($0.sirket) - \($0.aciklama)" }.joined(separator: " | "))
        Yetenekler: \(d.yetenekler.joined(separator: ", "))
        Egitim: \(d.egitimler.map { "\($0.okul) \($0.bolum)" }.joined(separator: ", "))
        Bu kisi icin 3-4 cumlelik profesyonel CV ozeti yaz.
        """
        do {
            let url = URL(string: "https://api.openai.com/v1/chat/completions")!
            var request = OpenAIService.shared.makeRequest(url: url)
            let body: [String: Any] = [
                "model": "gpt-4o-mini",
                "messages": [
                    ["role": "system", "content": "kişinin kendi ağzından, Turkce, kisa ve profesyonel CV ozeti yaz. eğitim bilgileri yer almasın."],
                    ["role": "user", "content": userPrompt],
                ],
                "temperature": 0.65,
                "max_tokens": 250,
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { throw URLError(.badServerResponse) }
            let text = try JSONDecoder().decode(OpenAIResponse.self, from: data).choices.first?.message.content?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !text.isEmpty {
                store.draft.ozet = text
            }
        } catch {
            // Kullanici manuel yazmaya devam edebilir.
        }
    }
}
