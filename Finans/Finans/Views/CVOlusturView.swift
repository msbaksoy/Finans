import SwiftUI
import UIKit
import PDFKit
import PhotosUI

struct CVOlusturView: View {
    @EnvironmentObject var appTheme: AppTheme
    @Environment(\.dismiss) private var dismiss
    @State private var model = CVModel.ornek
    @State private var showPdfShare = false
    @State private var pdfData: Data?
    @State private var onizlemeGosteriliyor = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Profil Fotoğrafı (sol panelde yuvarlak çerçevede)
                formSection(title: "Profil Fotoğrafı", icon: "person.crop.circle.fill") {
                    HStack(spacing: 16) {
                        if let data = model.fotografData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color(hex: "D97706").opacity(0.6), lineWidth: 2))
                        } else {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "E8E8E8"))
                                    .frame(width: 80, height: 80)
                                Image(systemName: "person.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(appTheme.textSecondary.opacity(0.6))
                            }
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                Label("Fotoğraf Seç", systemImage: "photo.on.rectangle.angled")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(Color(hex: "D97706"))
                            }
                            if model.fotografData != nil {
                                Button("Fotoğrafı Kaldır") {
                                    model.fotografData = nil
                                    selectedPhotoItem = nil
                                }
                                .font(.caption)
                                .foregroundColor(.red.opacity(0.9))
                            }
                            Text("CV'nin sol panelinde yuvarlak çerçevede görünecek")
                                .font(.caption)
                                .foregroundColor(appTheme.textSecondary)
                        }
                    }
                }
                .onChange(of: selectedPhotoItem) { _, newItem in
                    Task { @MainActor in
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            model.fotografData = data
                        }
                    }
                }
                
                // Kişisel Bilgiler
                formSection(title: "Kişisel Bilgiler", icon: "person.fill") {
                    formRow("Ad Soyad", text: $model.adSoyad)
                    formRow("Telefon", text: $model.telefon)
                    formRow("Adres (örn: İstanbul/Üsküdar)", text: $model.adres)
                    formRow("Doğum Tarihi (GG.AA.YYYY)", text: $model.dogumTarihi)
                    formRow("Uyruk", text: $model.uyruk)
                    formRow("E-posta", text: $model.email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }
                
                // Diller
                formSection(title: "Diller", icon: "globe") {
                    formRow("Diller (virgülle ayırın, örn: İngilizce, Arapça)", text: $model.diller)
                }
                
                // Özet
                formSection(title: "Özet", icon: "text.alignleft") {
                    TextEditor(text: $model.ozet)
                        .frame(minHeight: 100)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(appTheme.cardBackgroundSecondary))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(appTheme.cardStroke.opacity(0.5), lineWidth: 1))
                        .foregroundColor(appTheme.textPrimary)
                }
                
                // Yetkinlikler
                formSection(title: "Yetkinlikler", icon: "star.fill") {
                    TextEditor(text: $model.yetkinlikler)
                        .frame(minHeight: 80)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(appTheme.cardBackgroundSecondary))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(appTheme.cardStroke.opacity(0.5), lineWidth: 1))
                        .foregroundColor(appTheme.textPrimary)
                }
                
                // Sertifikalar
                formSection(title: "Sertifikalar", icon: "checkmark.seal.fill") {
                    TextEditor(text: $model.sertifikalar)
                        .frame(minHeight: 80)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(appTheme.cardBackgroundSecondary))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(appTheme.cardStroke.opacity(0.5), lineWidth: 1))
                        .foregroundColor(appTheme.textPrimary)
                }
                
                // Eğitimler
                formSection(title: "Eğitimler", icon: "graduationcap.fill") {
                    ForEach($model.egitimler) { $e in
                        egitimKarti(egitim: $e)
                    }
                    Button {
                        model.egitimler.append(EgitimGirisi())
                    } label: {
                        Label("Eğitim Ekle", systemImage: "plus.circle.fill")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(Color(hex: "F59E0B"))
                    }
                }
                
                // Deneyimler
                formSection(title: "Profesyonel Deneyim", icon: "briefcase.fill") {
                    ForEach($model.deneyimler) { $d in
                        deneyimKarti(deneyim: $d)
                    }
                    Button {
                        model.deneyimler.append(DeneyimGirisi())
                    } label: {
                        Label("Deneyim Ekle", systemImage: "plus.circle.fill")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(Color(hex: "F59E0B"))
                    }
                }
                
                // CV Oluştur (SwiftUI şablon + ImageRenderer → PDF)
                Button {
                    pdfData = CVTemplatePdfExporter.pdfData(from: model)
                    withAnimation(.easeInOut(duration: 0.3)) {
                        onizlemeGosteriliyor = pdfData != nil
                    }
                } label: {
                    HStack {
                        Image(systemName: "doc.fill")
                        Text("CV Oluştur")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "F59E0B"))
                    .foregroundColor(.white)
                    .cornerRadius(16)
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(model.adSoyad.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(model.adSoyad.trimmingCharacters(in: .whitespaces).isEmpty ? 0.6 : 1)
                
                // PDF Önizleme (CV Oluştur tıklanınca görünür)
                if onizlemeGosteriliyor, let data = pdfData {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Önizleme")
                                .font(.headline)
                                .foregroundColor(appTheme.textPrimary)
                            Spacer()
                            Button {
                                withAnimation { onizlemeGosteriliyor = false }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(appTheme.textSecondary)
                            }
                        }
                        CVPdfOnizlemeView(pdfData: data)
                            .frame(height: 520)
                            .background(Color(UIColor.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(appTheme.cardStroke.opacity(0.6), lineWidth: 1)
                            )
                        Button {
                            showPdfShare = true
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Paylaş")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "34D399"))
                            .foregroundColor(.white)
                            .cornerRadius(14)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(20)
                    .background(RoundedRectangle(cornerRadius: 20).fill(appTheme.listRowBackground))
                }
            }
            .padding(24)
        }
        .background(appTheme.background)
        .navigationTitle("CV Oluştur")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(appTheme.isLight ? .light : .dark, for: .navigationBar)
        .toolbarBackground(appTheme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Formu Temizle") {
                    model = CVModel()
                    selectedPhotoItem = nil
                    onizlemeGosteriliyor = false
                    pdfData = nil
                }
                .font(.subheadline)
                .foregroundColor(Color(hex: "F59E0B"))
            }
        }
        .sheet(isPresented: $showPdfShare) {
            if let data = pdfData {
                CVPdfShareSheet(pdfData: data)
            }
        }
    }
    
    private func formSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "F59E0B"))
                Text(title)
                    .font(.headline)
                    .foregroundColor(appTheme.textPrimary)
            }
            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16).fill(appTheme.listRowBackground))
        }
    }
    
    private func formRow(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(appTheme.textSecondary)
            TextField("", text: text)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(appTheme.cardBackgroundSecondary))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(appTheme.cardStroke.opacity(0.5), lineWidth: 1))
                .foregroundColor(appTheme.textPrimary)
        }
    }
    
    @ViewBuilder
    private func formRow(_ label: String, text: Binding<String>, keyboardType: UIKeyboardType = .default, textInputAutocapitalization: TextInputAutocapitalization = .sentences) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(appTheme.textSecondary)
            TextField("", text: text)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(textInputAutocapitalization)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(appTheme.cardBackgroundSecondary))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(appTheme.cardStroke.opacity(0.5), lineWidth: 1))
                .foregroundColor(appTheme.textPrimary)
        }
    }
    
    private func egitimKarti(egitim: Binding<EgitimGirisi>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Eğitim")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(appTheme.textPrimary)
                Spacer()
                Button {
                    model.egitimler.removeAll { $0.id == egitim.wrappedValue.id }
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red.opacity(0.8))
                }
            }
            HStack(spacing: 8) {
                TextField("Başlangıç (Yıl)", text: Binding(
                    get: { egitim.wrappedValue.baslangicYil },
                    set: { var c = egitim.wrappedValue; c.baslangicYil = $0; egitim.wrappedValue = c }
                ))
                .keyboardType(.numberPad)
                Text("–")
                TextField("Bitiş (Yıl)", text: Binding(
                    get: { egitim.wrappedValue.bitisYil },
                    set: { var c = egitim.wrappedValue; c.bitisYil = $0; egitim.wrappedValue = c }
                ))
                .keyboardType(.numberPad)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 8).fill(appTheme.cardBackgroundSecondary))
            
            Picker("Derece", selection: Binding(
                get: { egitim.wrappedValue.derece },
                set: { var c = egitim.wrappedValue; c.derece = $0; egitim.wrappedValue = c }
            )) {
                Text("Lisans").tag("Lisans")
                Text("Yüksek Lisans").tag("Yüksek Lisans")
                Text("Doktora").tag("Doktora")
            }
            .pickerStyle(.menu)
            
            formRow("Bölüm / Program", text: Binding(get: { egitim.wrappedValue.bolum }, set: { var c = egitim.wrappedValue; c.bolum = $0; egitim.wrappedValue = c }))
            formRow("Üniversite", text: Binding(get: { egitim.wrappedValue.universite }, set: { var c = egitim.wrappedValue; c.universite = $0; egitim.wrappedValue = c }))
            formRow("Şehir", text: Binding(get: { egitim.wrappedValue.sehir }, set: { var c = egitim.wrappedValue; c.sehir = $0; egitim.wrappedValue = c }))
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 12).fill(appTheme.cardBackgroundSecondary))
    }
    
    private func deneyimKarti(deneyim: Binding<DeneyimGirisi>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Deneyim")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(appTheme.textPrimary)
                Spacer()
                Button {
                    model.deneyimler.removeAll { $0.id == deneyim.wrappedValue.id }
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red.opacity(0.8))
                }
            }
            
            HStack(spacing: 4) {
                TextField("Baş. Ay", text: Binding(get: { deneyim.wrappedValue.baslangicAy }, set: { var c = deneyim.wrappedValue; c.baslangicAy = $0; deneyim.wrappedValue = c }))
                    .keyboardType(.numberPad)
                TextField("Baş. Yıl", text: Binding(get: { deneyim.wrappedValue.baslangicYil }, set: { var c = deneyim.wrappedValue; c.baslangicYil = $0; deneyim.wrappedValue = c }))
                    .keyboardType(.numberPad)
                Text("–")
                TextField("Bitiş Ay", text: Binding(get: { deneyim.wrappedValue.bitisAy }, set: { var c = deneyim.wrappedValue; c.bitisAy = $0; deneyim.wrappedValue = c }))
                    .keyboardType(.numberPad)
                TextField("Bitiş Yıl", text: Binding(get: { deneyim.wrappedValue.bitisYil }, set: { var c = deneyim.wrappedValue; c.bitisYil = $0; deneyim.wrappedValue = c }))
                    .keyboardType(.numberPad)
                Toggle("Devam", isOn: Binding(
                    get: { deneyim.wrappedValue.devamEdiyor },
                    set: { var c = deneyim.wrappedValue; c.devamEdiyor = $0; deneyim.wrappedValue = c }
                ))
                .labelsHidden()
            }
            .font(.caption)
            
            formRow("Pozisyon / Unvan", text: Binding(get: { deneyim.wrappedValue.pozisyon }, set: { var c = deneyim.wrappedValue; c.pozisyon = $0; deneyim.wrappedValue = c }))
            formRow("Şirket", text: Binding(get: { deneyim.wrappedValue.sirket }, set: { var c = deneyim.wrappedValue; c.sirket = $0; deneyim.wrappedValue = c }))
            formRow("Şehir", text: Binding(get: { deneyim.wrappedValue.sehir }, set: { var c = deneyim.wrappedValue; c.sehir = $0; deneyim.wrappedValue = c }))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Görevler (her satır bir madde)")
                    .font(.caption)
                    .foregroundColor(appTheme.textSecondary)
                TextEditor(text: Binding(get: { deneyim.wrappedValue.gorevler }, set: { var c = deneyim.wrappedValue; c.gorevler = $0; deneyim.wrappedValue = c }))
                    .frame(minHeight: 80)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 8).fill(appTheme.background))
                    .foregroundColor(appTheme.textPrimary)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 12).fill(appTheme.cardBackgroundSecondary))
    }
}

// MARK: - PDF Önizleme
struct CVPdfOnizlemeView: UIViewRepresentable {
    let pdfData: Data
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        if let doc = PDFDocument(data: pdfData) {
            pdfView.document = doc
        }
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        if let doc = PDFDocument(data: pdfData) {
            pdfView.document = doc
        }
    }
}

// MARK: - CV PDF Oluşturucu (Profesyonel iki sütunlu layout — EE-CV1 referans)
struct CVPdfOlusturucu {
    static func olustur(model: CVModel) -> Data? {
        let pageWidth: CGFloat = 595
        let pageHeight: CGFloat = 842
        let margin: CGFloat = 36
        let leftColX: CGFloat = margin
        let leftColWidth: CGFloat = 318
        let rightColX: CGFloat = 356
        let rightColWidth: CGFloat = pageWidth - rightColX - margin
        let dateColWidth: CGFloat = 72
        let accentColor = UIColor(red: 0.96, green: 0.62, blue: 0.04, alpha: 1)
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [kCGPDFContextCreator: "Finans - CV Oluşturucu"] as [String: Any]
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let nameFont = UIFont.boldSystemFont(ofSize: 24)
        let sectionFont = UIFont.boldSystemFont(ofSize: 11)
        let bodyFont = UIFont.systemFont(ofSize: 10)
        let smallFont = UIFont.systemFont(ofSize: 9)
        
        // Deneyimleri en yeniden en eskiye sırala (YYYYMM)
        let sortedDeneyim = model.deneyimler.sorted { a, b in
            let ma = a.baslangicAy.count == 1 ? "0" + a.baslangicAy : a.baslangicAy
            let mb = b.baslangicAy.count == 1 ? "0" + b.baslangicAy : b.baslangicAy
            let ya = Int(a.baslangicYil + ma) ?? 0
            let yb = Int(b.baslangicYil + mb) ?? 0
            return ya > yb
        }
        
        let data = renderer.pdfData { ctx in
            var leftY: CGFloat = margin
            var rightY: CGFloat = margin
            
            // İsim başlık (tam genişlik)
            model.adSoyad.draw(in: CGRect(x: leftColX, y: leftY, width: leftColWidth + rightColWidth + 20, height: 32), withAttributes: [
                .font: nameFont,
                .foregroundColor: UIColor(white: 0.15, alpha: 1)
            ])
            leftY += 36
            rightY += 36
            
            // İletişim bilgisi (telefon, adres)
            let iletisim = [model.telefon, model.adres].filter { !$0.isEmpty }.joined(separator: " · ")
            if !iletisim.isEmpty {
                iletisim.draw(in: CGRect(x: leftColX, y: leftY, width: leftColWidth, height: 14), withAttributes: [
                    .font: smallFont,
                    .foregroundColor: UIColor.darkGray
                ])
                leftY += 18
            }
            
            // Sol sütun: Eğitimler
            if !model.egitimler.isEmpty {
                leftY = drawSectionHeader(ctx: ctx, y: leftY, x: leftColX, width: leftColWidth, title: "Eğitimler", font: sectionFont, color: accentColor, pageHeight: pageHeight)
                for e in model.egitimler {
                    let tarih = "\(e.baslangicYil) - \(e.bitisYil)"
                    let contentW = leftColWidth - dateColWidth - 12
                    tarih.draw(in: CGRect(x: leftColX, y: leftY, width: dateColWidth, height: 14), withAttributes: [
                        .font: smallFont,
                        .foregroundColor: UIColor.darkGray
                    ])
                    let satir1 = "\(e.derece) - \(e.bolum)"
                    let h = drawWrapped(text: satir1, in: CGRect(x: leftColX + dateColWidth + 12, y: leftY, width: contentW, height: 80), font: bodyFont)
                    leftY += h + 2
                    "\(e.universite), \(e.sehir)".draw(in: CGRect(x: leftColX + dateColWidth + 12, y: leftY, width: contentW, height: 12), withAttributes: [
                        .font: smallFont,
                        .foregroundColor: UIColor.darkGray
                    ])
                    leftY += 22
                }
                leftY += 6
            }
            
            // Sol sütun: Profesyonel Deneyim
            if !sortedDeneyim.isEmpty {
                if leftY > pageHeight - 250 { ctx.beginPage(); leftY = margin; rightY = margin }
                leftY = drawSectionHeader(ctx: ctx, y: leftY, x: leftColX, width: leftColWidth, title: "Profesyonel Deneyim", font: sectionFont, color: accentColor, pageHeight: pageHeight)
                for d in sortedDeneyim {
                    let tarihStr = d.devamEdiyor ? "\(d.baslangicAy).\(d.baslangicYil) – Devam" : "\(d.baslangicAy).\(d.baslangicYil) – \(d.bitisAy).\(d.bitisYil)"
                    let contentW = leftColWidth - dateColWidth - 12
                    tarihStr.draw(in: CGRect(x: leftColX, y: leftY, width: dateColWidth, height: 12), withAttributes: [
                        .font: smallFont,
                        .foregroundColor: UIColor.darkGray
                    ])
                    d.pozisyon.draw(in: CGRect(x: leftColX + dateColWidth + 12, y: leftY, width: contentW, height: 14), withAttributes: [
                        .font: bodyFont,
                        .foregroundColor: UIColor.black
                    ])
                    leftY += 14
                    "\(d.sirket), \(d.sehir)".draw(in: CGRect(x: leftColX + dateColWidth + 12, y: leftY, width: contentW, height: 12), withAttributes: [
                        .font: smallFont,
                        .foregroundColor: UIColor.darkGray
                    ])
                    leftY += 14
                    for gorev in d.gorevler.split(separator: "\n").map(String.init).filter({ !$0.trimmingCharacters(in: .whitespaces).isEmpty }) {
                        let bullet = "•  \(gorev)"
                        let h = drawWrapped(text: bullet, in: CGRect(x: leftColX + dateColWidth + 12, y: leftY, width: contentW - 8, height: 80), font: smallFont)
                        leftY += h + 2
                    }
                    leftY += 10
                    if leftY > pageHeight - 150 { ctx.beginPage(); leftY = margin; rightY = margin }
                }
                leftY += 4
            }
            
            // Sağ sütun: Doğum, Diller, Özet, Email
            if !model.dogumTarihi.isEmpty {
                model.dogumTarihi.draw(in: CGRect(x: rightColX, y: rightY, width: rightColWidth, height: 12), withAttributes: [
                    .font: smallFont,
                    .foregroundColor: UIColor.darkGray
                ])
                rightY += 16
            }
            if !model.diller.trimmingCharacters(in: .whitespaces).isEmpty {
                model.diller.draw(in: CGRect(x: rightColX, y: rightY, width: rightColWidth, height: 14), withAttributes: [
                    .font: bodyFont,
                    .foregroundColor: UIColor.black
                ])
                rightY += 20
            }
            if !model.ozet.trimmingCharacters(in: .whitespaces).isEmpty {
                rightY = drawSectionHeader(ctx: ctx, y: rightY, x: rightColX, width: rightColWidth, title: "Özet", font: sectionFont, color: accentColor, pageHeight: pageHeight)
                let h = drawWrapped(text: model.ozet, in: CGRect(x: rightColX, y: rightY, width: rightColWidth, height: 280), font: smallFont)
                rightY += h + 16
            }
            if !model.email.isEmpty {
                model.email.draw(in: CGRect(x: rightColX, y: rightY, width: rightColWidth, height: 12), withAttributes: [
                    .font: smallFont,
                    .foregroundColor: UIColor.darkGray
                ])
            }
            
            // Sol sütun devam: Yetkinlikler
            if !model.yetkinlikler.trimmingCharacters(in: .whitespaces).isEmpty {
                if leftY > pageHeight - 200 { ctx.beginPage(); leftY = margin }
                leftY = drawSectionHeader(ctx: ctx, y: leftY, x: leftColX, width: leftColWidth, title: "Yetkinlikler", font: sectionFont, color: accentColor, pageHeight: pageHeight)
                for line in model.yetkinlikler.split(separator: "\n").map(String.init).filter({ !$0.trimmingCharacters(in: .whitespaces).isEmpty }) {
                    let txt = line.hasPrefix("•") ? line : "•  \(line)"
                    let h = drawWrapped(text: txt, in: CGRect(x: leftColX, y: leftY, width: leftColWidth - 8, height: 40), font: smallFont)
                    leftY += h + 2
                }
                leftY += 12
            }
            
            // Sol sütun devam: Sertifikalar
            if !model.sertifikalar.trimmingCharacters(in: .whitespaces).isEmpty {
                if leftY > pageHeight - 150 { ctx.beginPage(); leftY = margin }
                leftY = drawSectionHeader(ctx: ctx, y: leftY, x: leftColX, width: leftColWidth, title: "Sertifikalar", font: sectionFont, color: accentColor, pageHeight: pageHeight)
                for line in model.sertifikalar.split(separator: "\n").map(String.init).filter({ !$0.trimmingCharacters(in: .whitespaces).isEmpty }) {
                    let txt = line.hasPrefix("•") ? line : "•  \(line)"
                    let h = drawWrapped(text: txt, in: CGRect(x: leftColX, y: leftY, width: leftColWidth - 8, height: 40), font: smallFont)
                    leftY += h + 2
                }
            }
        }
        return data
    }
    
    private static func drawSectionHeader(ctx: UIGraphicsPDFRendererContext, y: CGFloat, x: CGFloat, width: CGFloat, title: String, font: UIFont, color: UIColor, pageHeight: CGFloat) -> CGFloat {
        var yy = y
        if yy > pageHeight - 100 {
            ctx.beginPage()
            yy = 36
        }
        title.draw(in: CGRect(x: x, y: yy, width: width, height: 14), withAttributes: [
            .font: font,
            .foregroundColor: color
        ])
        yy += 18
        return yy
    }
    
    private static func drawWrapped(text: String, in rect: CGRect, font: UIFont) -> CGFloat {
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byWordWrapping
        style.lineSpacing = 2
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.black,
            .paragraphStyle: style
        ]
        let ns = NSString(string: text)
        let boundingRect = ns.boundingRect(with: CGSize(width: rect.width, height: 600), options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
        ns.draw(in: CGRect(x: rect.origin.x, y: rect.origin.y, width: rect.width, height: boundingRect.height + 4), withAttributes: attrs)
        return boundingRect.height + 4
    }
}

// MARK: - CV PDF Paylaşım
struct CVPdfShareSheet: UIViewControllerRepresentable {
    let pdfData: Data
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("CV_\(Date().timeIntervalSince1970).pdf")
        try? pdfData.write(to: tempURL)
        return UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        CVOlusturView()
            .environmentObject(AppTheme())
    }
}
