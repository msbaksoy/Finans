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
                .shadow(color: .black.opacity(appTheme.isLight ? 0.03 : 0), radius: appTheme.isLight ? 8 : 0, y: 4)
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
                .padding(.vertical, 18)
                .background(Color(hex: "06B6D4").opacity(0.2))
                .foregroundColor(Color(hex: "06B6D4"))
                .cornerRadius(16)
        }
    }
}

struct KonutKredisiTabloView: View {
    let odemePlani: [KrediCalculator.KonutOdemeSatiri]
    @EnvironmentObject var appTheme: AppTheme
    @State private var tumunuGoster = false
    private let ilkGosterim = 5
    private let temaRengi = Color(hex: "06B6D4")
    
    private var gosterilecekPlani: [KrediCalculator.KonutOdemeSatiri] {
        if tumunuGoster || odemePlani.count <= ilkGosterim {
            return odemePlani
        }
        return Array(odemePlani.prefix(ilkGosterim))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "list.bullet.rectangle")
                    .foregroundColor(temaRengi)
                Text("Ödeme Planı")
                    .font(.headline)
                    .foregroundColor(appTheme.textPrimary)
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
                        LinearGradient(colors: [temaRengi.opacity(0.25), temaRengi.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    Divider().background(appTheme.cardStroke)
                    ForEach(gosterilecekPlani) { satir in
                        KonutTaksitSatirView(satir: satir)
                    }
                    if odemePlani.count > ilkGosterim {
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) { tumunuGoster.toggle() }
                        } label: {
                            HStack(spacing: 6) {
                                Text(tumunuGoster ? "Daha Az Göster" : "Tümünü Göster (\(odemePlani.count) taksit)")
                                    .font(AppTypography.footnote.weight(.semibold))
                                Image(systemName: tumunuGoster ? "chevron.up" : "chevron.down")
                                    .font(AppTypography.caption1.weight(.semibold))
                            }
                            .foregroundColor(temaRengi)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(10)
            }
            .background(
                RoundedRectangle(cornerRadius: AppSpacing.lg)
                    .fill(appTheme.listRowBackground)
                    .overlay(RoundedRectangle(cornerRadius: AppSpacing.lg).stroke(Color(hex: "06B6D4").opacity(0.3), lineWidth: 1))
            )
        }
    }
}

struct KonutTaksitSatirView: View {
    let satir: KrediCalculator.KonutOdemeSatiri
    @EnvironmentObject var appTheme: AppTheme
    
    var body: some View {
        HStack(spacing: 0) {
            Text("\(satir.taksitNo)")
                .frame(width: 48, alignment: .center)
                .font(AppTypography.subheadline)
                .foregroundColor(appTheme.textPrimary)
            Text(formatCurrency(satir.taksitTutari))
                .frame(width: 100, alignment: .trailing)
                .font(AppTypography.footnote)
                .monospacedDigit()
                .foregroundColor(appTheme.textPrimary)
            Text(formatCurrency(satir.anapara))
                .frame(width: 100, alignment: .trailing)
                .font(AppTypography.footnote)
                .monospacedDigit()
                .foregroundColor(Color(hex: "34D399"))
            Text(formatCurrency(satir.faiz))
                .frame(width: 100, alignment: .trailing)
                .font(AppTypography.footnote)
                .monospacedDigit()
                .foregroundColor(appTheme.textPrimary)
            Text(formatCurrency(satir.kalanAnapara))
                .frame(width: 100, alignment: .trailing)
                .font(AppTypography.footnote)
                .monospacedDigit()
                .foregroundColor(appTheme.textSecondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(satir.taksitNo.isMultiple(of: 2) ? appTheme.textSecondary.opacity(0.05) : Color.clear)
    }
}

#Preview {
    NavigationStack {
        KonutKredisiView()
            .environmentObject(AppTheme())
    }
}
