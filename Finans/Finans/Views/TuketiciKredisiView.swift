import SwiftUI
import UIKit

struct TuketiciKredisiView: View {
    @EnvironmentObject var appTheme: AppTheme
    @EnvironmentObject var krediConfig: KrediConfigService
    @State private var anaparaText = ""
    @State private var vadeText = ""
    @State private var faizOraniText = ""
    @State private var pdfData: Data?
    @State private var showPdfShare = false
    @State private var isRefreshing = false
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    private var odemePlani: [KrediCalculator.OdemeSatiri] {
        guard let anapara = parseFormattedNumber(anaparaText),
              let vadeD = parseFormattedNumber(vadeText),
              let faiz = parseFormattedNumber(faizOraniText),
              anapara > 0, faiz >= 0
        else { return [] }
        let vade = Int(vadeD)
        guard vade >= 1, vade <= 60 else { return [] }
        let c = krediConfig.config
        return KrediCalculator.tuketiciKredisiHesapla(anapara: anapara, vade: vade, aylikFaizOrani: faiz, kkdfOrani: c.kkdfOrani, bsmvOrani: c.bsmvOrani)
    }
    
    private var toplamFaiz: Double {
        odemePlani.reduce(0) { $0 + $1.faiz }
    }
    
    private var isLandscape: Bool { verticalSizeClass == .compact }
    
    var body: some View {
        ZStack {
            appTheme.background.ignoresSafeArea()
            
            // Ödeme planı tablosu kaldırıldı; sadece giriş ve özet kartlar gösteriliyor.
            tuketiciPortraitView
        }
        .navigationTitle("Tüketici Kredisi")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(appTheme.isLight ? .light : .dark, for: .navigationBar)
        .toolbarBackground(appTheme.background, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isRefreshing = true
                    Task {
                        await krediConfig.refresh()
                        isRefreshing = false
                    }
                } label: {
                    Label("Oranları Yenile", systemImage: "arrow.clockwise")
                        .font(.subheadline)
                }
                .disabled(isRefreshing)
            }
        }
        .sheet(isPresented: $showPdfShare) {
            if let data = pdfData {
                PdfShareSheet(pdfData: data)
            }
        }
    }
    
    private var tuketiciPortraitView: some View {
        ScrollView {
            VStack(spacing: 16) {
                girisAlani
                if !odemePlani.isEmpty {
                    ozetKartlar
                    pdfButon
                }
            }
            .padding(16)
            .contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }
    
    private var girisAlani: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                KrediTextField(title: "Anapara (₺)", text: $anaparaText, placeholder: "50.000", keyboardType: .decimalPad, formatThousands: true)
                    .frame(maxWidth: .infinity)
                KrediTextField(title: "Vade (ay)", text: $vadeText, placeholder: "12", keyboardType: .numberPad, formatThousands: true)
                    .frame(maxWidth: .infinity)
            }
            KrediTextField(title: "Aylık Faiz (%)", text: $faizOraniText, placeholder: "4,99", keyboardType: .decimalPad, suffix: "%", formatThousands: true, allowDecimals: true)
            Text("KKDF %\(Int(krediConfig.config.kkdfOrani * 100)) · BSMV %\(Int(krediConfig.config.bsmvOrani * 100))")
                .font(.caption)
                .foregroundColor(appTheme.textSecondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(appTheme.listRowBackground)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color("8B5CF6").opacity(0.25), lineWidth: 1))
                .shadow(color: .black.opacity(appTheme.isLight ? 0.03 : 0), radius: appTheme.isLight ? 8 : 0, y: 4)
        )
    }
    
    private var ozetKartlar: some View {
        HStack(spacing: 10) {
            OzetKrediKart(title: "Aylık Taksit", value: odemePlani.first?.taksitTutari ?? 0, color: Color("8B5CF6"), icon: "calendar")
                .frame(minWidth: 100)
            OzetKrediKart(title: "Toplam Faiz", value: toplamFaiz, color: Color("F59E0B"), icon: "percent")
                .frame(minWidth: 100)
            OzetKrediKart(title: "Top. Maliyet", value: odemePlani.reduce(0) { $0 + $1.taksitTutari }, color: Color("34D399"), icon: "sum")
                .frame(minWidth: 100)
        }
    }
    
    private var pdfButon: some View {
        Button {
            pdfData = KrediPdfOlusturucu.tuketiciPdf(
                anapara: anaparaText, vade: vadeText, faiz: faizOraniText,
                plan: odemePlani,
                aylikTaksit: odemePlani.first?.taksitTutari ?? 0,
                toplamFaiz: toplamFaiz,
                toplamMaliyet: odemePlani.reduce(0) { $0 + $1.taksitTutari }
            )
            showPdfShare = true
        } label: {
            Label("PDF Olarak Dışa Aktar", systemImage: "square.and.arrow.up")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color("8B5CF6").opacity(0.2))
                .foregroundColor(Color("8B5CF6"))
                .cornerRadius(14)
        }
    }
}

/// Yazarken her tuşta binlik nokta formatlaması uygular (200 → 200.000)
struct AnaparaTextField: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    @Binding var focusTrigger: Bool
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UITextField {
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.keyboardType = .decimalPad
        tf.delegate = context.coordinator
        tf.textColor = .white
        tf.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        context.coordinator.syncFromBinding(to: tf)
        return tf
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text && !context.coordinator.isEditing {
            context.coordinator.syncFromBinding(to: uiView)
        }
        if focusTrigger {
            uiView.becomeFirstResponder()
            DispatchQueue.main.async { focusTrigger = false }
        }
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: AnaparaTextField
        var isEditing = false
        
        init(_ parent: AnaparaTextField) {
            self.parent = parent
        }
        
        func syncFromBinding(to tf: UITextField) {
            let formatted = formatAnaparaGiris(parent.text)
            if tf.text != formatted {
                tf.text = formatted
            }
        }
        
        func textFieldDidBeginEditing(_ textField: UITextField) {
            isEditing = true
        }
        
        func textFieldDidEndEditing(_ textField: UITextField) {
            isEditing = false
        }
        
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let current = textField.text ?? ""
            let ns = current as NSString
            let proposed = ns.replacingCharacters(in: range, with: string)
            let digits = proposed.filter { $0.isNumber }
            let formatted = formatAnaparaGiris(digits)
            textField.text = formatted
            parent.text = formatted
            return false
        }
    }
}

struct KrediTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    var suffix: String = ""
    var formatThousands: Bool = false
    /// formatThousands true iken: ondalık kısmı da formatla (örn. faiz: 4,99)
    var allowDecimals: Bool = false
    
    @FocusState private var isFocused: Bool
    @State private var triggerFocus = false
    @EnvironmentObject var appTheme: AppTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(appTheme.textSecondary)
            HStack(spacing: 0) {
                if formatThousands {
                    FormattedNumberField(text: $text, placeholder: placeholder, allowDecimals: allowDecimals, focusTrigger: $triggerFocus, isLightMode: appTheme.isLight)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .foregroundColor(.white)
                        .focused($isFocused)
                }
                if !suffix.isEmpty {
                    Text(suffix)
                        .font(.subheadline)
                        .foregroundColor(appTheme.textSecondary.opacity(0.8))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(appTheme.cardBackgroundSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(appTheme.cardStroke.opacity(0.6), lineWidth: 1)
                    )
            )
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if formatThousands {
                triggerFocus = true
            } else {
                isFocused = true
            }
        }
    }
}

struct OzetKrediKart: View {
    let title: String
    let value: Double
    let color: Color
    var icon: String = "creditcard"
    @EnvironmentObject var appTheme: AppTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(AppTypography.caption1)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption2)
                    .foregroundColor(appTheme.textSecondary)
                    .lineLimit(1)
            }
            Text(formatCurrency(value))
                .font(AppTypography.amountSmall)
                .monospacedDigit()
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .layoutPriority(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minWidth: 90)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(color.opacity(0.12))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.25), lineWidth: 1))
                .shadow(color: .black.opacity(appTheme.isLight ? 0.03 : 0), radius: appTheme.isLight ? 8 : 0, y: 4)
        )
    }
}

#Preview {
    NavigationStack {
        TuketiciKredisiView()
            .environmentObject(AppTheme())
    }
}
