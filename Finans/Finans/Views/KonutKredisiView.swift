import SwiftUI
import UIKit

struct KonutKredisiView: View {
    @EnvironmentObject var appTheme: AppTheme
    @State private var anaparaText = ""
    @State private var vadeText = ""
    @State private var faizOraniText = ""
    @State private var pdfData: Data?
    @State private var showPdfShare = false
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    private var odemePlani: [KrediCalculator.KonutOdemeSatiri] {
        guard let anapara = parseFormattedNumber(anaparaText),
              let vadeD = parseFormattedNumber(vadeText),
              let faiz = parseFormattedNumber(faizOraniText),
              anapara > 0, faiz >= 0
        else { return [] }
        let vade = Int(vadeD)
        guard vade >= 1, vade <= 120 else { return [] }
        return KrediCalculator.konutKredisiHesapla(anapara: anapara, vade: vade, aylikFaizOrani: faiz)
    }
    
    private var isLandscape: Bool { verticalSizeClass == .compact }
    
    var body: some View {
        ZStack {
            appTheme.background.ignoresSafeArea()
            
            // Ödeme planı tablosu kaldırıldı; sadece giriş, özet ve PDF gösteriliyor.
            konutPortraitView
        }
        .navigationTitle("Konut Kredisi")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(appTheme.isLight ? .light : .dark, for: .navigationBar)
        .toolbarBackground(appTheme.background, for: .navigationBar)
        .sheet(isPresented: $showPdfShare) {
            if let data = pdfData {
                PdfShareSheet(pdfData: data)
            }
        }
    }
    
    private var konutPortraitView: some View {
        ScrollView {
            VStack(spacing: 20) {
                konutGirisAlani
                if !odemePlani.isEmpty {
                    konutOzetKartlar
                    pdfButon
                }
            }
            .padding(20)
            .contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }
    
    private var konutGirisAlani: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                KrediTextField(title: "Anapara (₺)", text: $anaparaText, placeholder: "2.000.000", keyboardType: .decimalPad, formatThousands: true)
                    .frame(maxWidth: .infinity)
                KrediTextField(title: "Vade (ay)", text: $vadeText, placeholder: "120", keyboardType: .numberPad, formatThousands: true)
                    .frame(maxWidth: .infinity)
            }
            KrediTextField(title: "Aylık Faiz (%)", text: $faizOraniText, placeholder: "2,50", keyboardType: .decimalPad, suffix: "%", formatThousands: true, allowDecimals: true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(appTheme.listRowBackground)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color("06B6D4").opacity(0.3), lineWidth: 1))
                .shadow(color: .black.opacity(appTheme.isLight ? 0.03 : 0), radius: appTheme.isLight ? 8 : 0, y: 4)
        )
    }
    
    private var konutOzetKartlar: some View {
        HStack(spacing: 12) {
            OzetKrediKart(title: "Aylık Taksit", value: odemePlani.first?.taksitTutari ?? 0, color: Color("06B6D4"), icon: "calendar")
                .frame(minWidth: 100)
            OzetKrediKart(title: "Toplam Faiz", value: odemePlani.reduce(0) { $0 + $1.faiz }, color: Color("F59E0B"), icon: "percent")
                .frame(minWidth: 100)
            OzetKrediKart(title: "Top. Maliyet", value: odemePlani.reduce(0) { $0 + $1.taksitTutari }, color: Color("34D399"), icon: "sum")
                .frame(minWidth: 100)
        }
    }
    
    private var pdfButon: some View {
        Button {
            pdfData = KrediPdfOlusturucu.konutPdf(anapara: anaparaText, vade: vadeText, faiz: faizOraniText, plan: odemePlani)
            showPdfShare = true
        } label: {
            Label("PDF Olarak Dışa Aktar", systemImage: "square.and.arrow.up")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color("06B6D4").opacity(0.2))
                .foregroundColor(Color("06B6D4"))
                .cornerRadius(16)
        }
    }
}

#Preview {
    NavigationStack {
        KonutKredisiView()
            .environmentObject(AppTheme())
    }
}
