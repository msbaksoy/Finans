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
            
            if isLandscape && !odemePlani.isEmpty {
                konutLandscapeView
            } else {
                konutPortraitView
            }
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
    
    private var konutLandscapeView: some View {
        ZStack(alignment: .topTrailing) {
            KonutKredisiTabloView(odemePlani: odemePlani)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Button {
                pdfData = KrediPdfOlusturucu.konutPdf(anapara: anaparaText, vade: vadeText, faiz: faizOraniText, plan: odemePlani)
                showPdfShare = true
            } label: {
                Label("PDF", systemImage: "square.and.arrow.up")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color(hex: "06B6D4"))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(appTheme.backgroundSecondary.opacity(0.95))
                    .cornerRadius(12)
            }
            .padding(16)
        }
    }
    
    private var konutPortraitView: some View {
        ScrollView {
            VStack(spacing: 20) {
                konutGirisAlani
                if !odemePlani.isEmpty {
                    konutOzetKartlar
                    KonutKredisiTabloView(odemePlani: odemePlani)
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
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "06B6D4").opacity(0.3), lineWidth: 1))
                .shadow(color: .black.opacity(appTheme.isLight ? 0.06 : 0), radius: appTheme.isLight ? 6 : 0, y: 2)
        )
    }
    
    private var konutOzetKartlar: some View {
        HStack(spacing: 12) {
            OzetKrediKart(title: "Aylık Taksit", value: odemePlani.first?.taksitTutari ?? 0, color: Color(hex: "06B6D4"), icon: "calendar")
            OzetKrediKart(title: "Toplam Faiz", value: odemePlani.reduce(0) { $0 + $1.faiz }, color: Color(hex: "F59E0B"), icon: "percent")
            OzetKrediKart(title: "Toplam Maliyet", value: odemePlani.reduce(0) { $0 + $1.taksitTutari }, color: Color(hex: "34D399"), icon: "sum")
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
                .padding(14)
                .background(Color(hex: "06B6D4").opacity(0.2))
                .foregroundColor(Color(hex: "06B6D4"))
                .cornerRadius(16)
        }
    }
}

struct KonutKredisiTabloView: View {
    let odemePlani: [KrediCalculator.KonutOdemeSatiri]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "list.bullet.rectangle")
                    .foregroundColor(Color(hex: "06B6D4"))
                Text("Ödeme Planı")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            ScrollView([.horizontal, .vertical]) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 0) {
                        TabloBaslik(text: "No", width: 48)
                        TabloBaslik(text: "Taksit", width: 100)
                        TabloBaslik(text: "Anapara", width: 100)
                        TabloBaslik(text: "Faiz", width: 100)
                        TabloBaslik(text: "Kalan", width: 100)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(colors: [Color(hex: "06B6D4").opacity(0.25), Color(hex: "06B6D4").opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    Divider().background(Color.white.opacity(0.2))
                    ForEach(odemePlani) { satir in
                        KonutTaksitSatirView(satir: satir)
                    }
                }
                .padding(10)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
            )
        }
    }
}

struct KonutTaksitSatirView: View {
    let satir: KrediCalculator.KonutOdemeSatiri
    
    var body: some View {
        HStack(spacing: 0) {
            Text("\(satir.taksitNo)")
                .frame(width: 48, alignment: .center)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
            Text(formatCurrency(satir.taksitTutari))
                .frame(width: 100, alignment: .trailing)
                .font(.subheadline)
                .foregroundColor(.white)
            Text(formatCurrency(satir.anapara))
                .frame(width: 100, alignment: .trailing)
                .font(.subheadline)
                .foregroundColor(Color(hex: "34D399"))
            Text(formatCurrency(satir.faiz))
                .frame(width: 100, alignment: .trailing)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
            Text(formatCurrency(satir.kalanAnapara))
                .frame(width: 100, alignment: .trailing)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(satir.taksitNo.isMultiple(of: 2) ? Color.white.opacity(0.02) : Color.clear)
    }
}

#Preview {
    NavigationStack {
        KonutKredisiView()
            .environmentObject(AppTheme())
    }
}
