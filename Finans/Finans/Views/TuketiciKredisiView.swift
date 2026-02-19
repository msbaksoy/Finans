import SwiftUI
import UIKit

struct TuketiciKredisiView: View {
    @State private var anaparaText = ""
    @State private var vadeText = ""
    @State private var faizOraniText = ""
    @State private var pdfData: Data?
    @State private var showPdfShare = false
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    private var odemePlani: [KrediCalculator.OdemeSatiri] {
        guard let anapara = Double(anaparaText.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")),
              let vade = Int(vadeText),
              let faiz = Double(faizOraniText.replacingOccurrences(of: ",", with: ".")),
              anapara > 0, vade >= 1, vade <= 60, faiz >= 0
        else { return [] }
        return KrediCalculator.tuketiciKredisiHesapla(anapara: anapara, vade: vade, aylikFaizOrani: faiz)
    }
    
    private var toplamFaiz: Double {
        odemePlani.reduce(0) { $0 + $1.faiz }
    }
    
    private var isLandscape: Bool { verticalSizeClass == .compact }
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "0F172A"), Color(hex: "1a1f3a")], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            if isLandscape && !odemePlani.isEmpty {
                tuketiciLandscapeView
            } else {
                tuketiciPortraitView
            }
        }
        .navigationTitle("Tüketici Kredisi")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color(hex: "0F172A"), for: .navigationBar)
        .sheet(isPresented: $showPdfShare) {
            if let data = pdfData {
                PdfShareSheet(pdfData: data)
            }
        }
    }
    
    private var tuketiciLandscapeView: some View {
        ZStack(alignment: .topTrailing) {
            TuketiciKredisiTablo(odemePlani: odemePlani)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
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
                Label("PDF", systemImage: "square.and.arrow.up")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color(hex: "8B5CF6"))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(hex: "1E293B").opacity(0.95))
                    .cornerRadius(12)
            }
            .padding(16)
        }
    }
    
    private var tuketiciPortraitView: some View {
        ScrollView {
            VStack(spacing: 16) {
                girisAlani
                if !odemePlani.isEmpty {
                    ozetKartlar
                    TuketiciKredisiTablo(odemePlani: odemePlani)
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
                KrediTextField(title: "Vade (ay)", text: $vadeText, placeholder: "12", keyboardType: .numberPad)
                    .frame(maxWidth: .infinity)
            }
            KrediTextField(title: "Aylık Faiz (%)", text: $faizOraniText, placeholder: "4,99", keyboardType: .decimalPad, suffix: "%")
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "8B5CF6").opacity(0.25), lineWidth: 1))
        )
    }
    
    private var ozetKartlar: some View {
        HStack(spacing: 10) {
            OzetKrediKart(title: "Aylık Taksit", value: odemePlani.first?.taksitTutari ?? 0, color: Color(hex: "8B5CF6"), icon: "calendar")
            OzetKrediKart(title: "Toplam Faiz", value: toplamFaiz, color: Color(hex: "F59E0B"), icon: "percent")
            OzetKrediKart(title: "Toplam Maliyet", value: odemePlani.reduce(0) { $0 + $1.taksitTutari }, color: Color(hex: "34D399"), icon: "sum")
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
                .padding(12)
                .background(Color(hex: "8B5CF6").opacity(0.2))
                .foregroundColor(Color(hex: "8B5CF6"))
                .cornerRadius(14)
        }
    }
}

/// Yazarken her tuşta binlik nokta formatlaması uygular (200 → 200.000)
struct AnaparaTextField: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white.opacity(0.85))
            HStack(spacing: 0) {
                if formatThousands {
                    AnaparaTextField(text: $text, placeholder: placeholder)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .foregroundColor(.white)
                }
                if !suffix.isEmpty {
                    Text(suffix)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
            )
        }
    }
}

struct OzetKrediKart: View {
    let title: String
    let value: Double
    let color: Color
    var icon: String = "creditcard"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.75))
                    .lineLimit(1)
            }
            Text(formatCurrency(value))
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(color.opacity(0.12))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.25), lineWidth: 1))
        )
    }
}

struct TuketiciKredisiTablo: View {
    let odemePlani: [KrediCalculator.OdemeSatiri]
    var temaRengi: Color = Color(hex: "8B5CF6")
    
    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    TabloBaslik(text: "No", width: 44)
                    TabloBaslik(text: "Taksit", width: 92)
                    TabloBaslik(text: "Anapara", width: 92)
                    TabloBaslik(text: "Faiz", width: 82)
                    TabloBaslik(text: "KKDF", width: 72)
                    TabloBaslik(text: "BSMV", width: 72)
                    TabloBaslik(text: "Kalan", width: 92)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [temaRengi.opacity(0.25), temaRengi.opacity(0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                Divider().background(Color.white.opacity(0.2))
                ForEach(odemePlani) { satir in
                    TaksitSatirView(satir: satir)
                }
            }
            .padding(12)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

struct TaksitSatirView: View {
    let satir: KrediCalculator.OdemeSatiri
    
    var body: some View {
        HStack(spacing: 0) {
            Text("\(satir.taksitNo)")
                .frame(width: 44, alignment: .center)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white.opacity(0.9))
            Text(formatCurrency(satir.taksitTutari))
                .frame(width: 92, alignment: .trailing)
                .font(.subheadline)
                .foregroundColor(.white)
            Text(formatCurrency(satir.anapara))
                .frame(width: 92, alignment: .trailing)
                .font(.subheadline)
                .foregroundColor(Color(hex: "34D399"))
            Text(formatCurrency(satir.faiz))
                .frame(width: 82, alignment: .trailing)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
            Text(formatCurrency(satir.kkdf))
                .frame(width: 72, alignment: .trailing)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.85))
            Text(formatCurrency(satir.bsmv))
                .frame(width: 72, alignment: .trailing)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.85))
            Text(formatCurrency(satir.kalanAnapara))
                .frame(width: 92, alignment: .trailing)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(satir.taksitNo.isMultiple(of: 2) ? Color.white.opacity(0.02) : Color.clear)
    }
}

struct TabloBaslik: View {
    let text: String
    let width: CGFloat
    
    var body: some View {
        Text(text)
            .frame(width: width, alignment: text == "No" ? .center : .trailing)
            .font(.caption.weight(.semibold))
            .foregroundColor(.white.opacity(0.95))
    }
}

#Preview {
    NavigationStack {
        TuketiciKredisiView()
    }
}
