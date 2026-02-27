import SwiftUI
import UIKit

struct TasitKredisiView: View {
    @EnvironmentObject var appTheme: AppTheme
    @EnvironmentObject var krediConfig: KrediConfigService
    @State private var anaparaText = ""
    @State private var vadeText = ""
    @State private var faizOraniText = ""
    @State private var pdfData: Data?
    @State private var showPdfShare = false
    @State private var isRefreshing = false
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    private static let temaRengi = Color("F59E0B")
    
    private var odemePlani: [KrediCalculator.OdemeSatiri] {
        guard let anapara = parseFormattedNumber(anaparaText),
              let vadeD = parseFormattedNumber(vadeText),
              let faiz = parseFormattedNumber(faizOraniText),
              anapara > 0, faiz >= 0
        else { return [] }
        let vade = Int(vadeD)
        guard vade >= 1, vade <= 48 else { return [] }
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
            
            // Ödeme planı tablosu kaldırıldı; sadece giriş, özet ve PDF gösteriliyor.
            tasitPortraitView
        }
        .navigationTitle("Taşıt Kredisi")
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
    
    private var tasitPortraitView: some View {
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
                KrediTextField(title: "Anapara (₺)", text: $anaparaText, placeholder: "500.000", keyboardType: .decimalPad, formatThousands: true)
                    .frame(maxWidth: .infinity)
                KrediTextField(title: "Vade (ay)", text: $vadeText, placeholder: "48", keyboardType: .numberPad, formatThousands: true)
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
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Self.temaRengi.opacity(0.25), lineWidth: 1))
                .shadow(color: .black.opacity(appTheme.isLight ? 0.06 : 0), radius: appTheme.isLight ? 6 : 0, y: 2)
        )
    }
    
    private var ozetKartlar: some View {
        HStack(spacing: 10) {
            OzetKrediKart(title: "Aylık Taksit", value: odemePlani.first?.taksitTutari ?? 0, color: Self.temaRengi, icon: "calendar")
                .frame(minWidth: 100)
            OzetKrediKart(title: "Toplam Faiz", value: toplamFaiz, color: Color("F59E0B"), icon: "percent")
                .frame(minWidth: 100)
            OzetKrediKart(title: "Top. Maliyet", value: odemePlani.reduce(0) { $0 + $1.taksitTutari }, color: Color("34D399"), icon: "sum")
                .frame(minWidth: 100)
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
