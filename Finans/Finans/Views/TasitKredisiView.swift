import SwiftUI
import UIKit

struct TasitKredisiView: View {
    @State private var anaparaText = ""
    @State private var vadeText = ""
    @State private var faizOraniText = ""
    @State private var pdfData: Data?
    @State private var showPdfShare = false
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    private static let temaRengi = Color(hex: "F59E0B")
    
    private var odemePlani: [KrediCalculator.OdemeSatiri] {
        guard let anapara = Double(anaparaText.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")),
              let vade = Int(vadeText),
              let faiz = Double(faizOraniText.replacingOccurrences(of: ",", with: ".")),
              anapara > 0, vade >= 1, vade <= 48, faiz >= 0
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
                tasitLandscapeView
            } else {
                tasitPortraitView
            }
        }
        .navigationTitle("Taşıt Kredisi")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color(hex: "0F172A"), for: .navigationBar)
        .sheet(isPresented: $showPdfShare) {
            if let data = pdfData {
                PdfShareSheet(pdfData: data)
            }
        }
    }
    
    private var tasitLandscapeView: some View {
        ZStack(alignment: .topTrailing) {
            TuketiciKredisiTablo(odemePlani: odemePlani, temaRengi: Self.temaRengi)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Button {
                pdfData = KrediPdfOlusturucu.tasitPdf(
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
                    .foregroundColor(Self.temaRengi)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(hex: "1E293B").opacity(0.95))
                    .cornerRadius(12)
            }
            .padding(16)
        }
    }
    
    private var tasitPortraitView: some View {
        ScrollView {
            VStack(spacing: 16) {
                girisAlani
                if !odemePlani.isEmpty {
                    ozetKartlar
                    TuketiciKredisiTablo(odemePlani: odemePlani, temaRengi: Self.temaRengi)
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
                KrediTextField(title: "Anapara (₺)", text: $anaparaText, placeholder: "500.000", keyboardType: .decimalPad, formatThousands: true)
                    .frame(maxWidth: .infinity)
                KrediTextField(title: "Vade (ay)", text: $vadeText, placeholder: "48", keyboardType: .numberPad)
                    .frame(maxWidth: .infinity)
            }
            KrediTextField(title: "Aylık Faiz (%)", text: $faizOraniText, placeholder: "4,99", keyboardType: .decimalPad, suffix: "%")
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Self.temaRengi.opacity(0.25), lineWidth: 1))
        )
    }
    
    private var ozetKartlar: some View {
        HStack(spacing: 10) {
            OzetKrediKart(title: "Aylık Taksit", value: odemePlani.first?.taksitTutari ?? 0, color: Self.temaRengi, icon: "calendar")
            OzetKrediKart(title: "Toplam Faiz", value: toplamFaiz, color: Color(hex: "F59E0B"), icon: "percent")
            OzetKrediKart(title: "Toplam Maliyet", value: odemePlani.reduce(0) { $0 + $1.taksitTutari }, color: Color(hex: "34D399"), icon: "sum")
        }
    }
    
    private var pdfButon: some View {
        Button {
            pdfData = KrediPdfOlusturucu.tasitPdf(
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
                .background(Self.temaRengi.opacity(0.2))
                .foregroundColor(Self.temaRengi)
                .cornerRadius(14)
        }
    }
}

#Preview {
    NavigationStack {
        TasitKredisiView()
    }
}
