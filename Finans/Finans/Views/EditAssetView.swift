import SwiftUI

struct EditAssetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    let asset: Asset
    
    @State private var name: String = ""
    @State private var quantity: String = ""
    @State private var pricePerUnit: String = ""
    @State private var totalAmount: String = ""
    @FocusState private var nameFocused: Bool
    @State private var triggerQuantityFocus = false
    @State private var triggerPriceFocus = false
    @State private var triggerTotalFocus = false
    
    private var isQuantityBased: Bool { asset.type.supportsQuantityAndPrice }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0F172A").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Tür (sadece gösterim)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Varlık Türü")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.white.opacity(0.8))
                            Text(asset.displayType)
                                .font(.body)
                                .foregroundColor(.white.opacity(0.9))
                                .padding(20)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.06))
                                )
                        }
                        
                        // Ad
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Ad")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.white.opacity(0.8))
                            TextField("Ad", text: $name)
                                .foregroundColor(.white)
                                .padding(20)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.08))
                                )
                                .focused($nameFocused)
                        }
                        .tappableToFocus($nameFocused)
                        
                        if isQuantityBased {
                            // Adet
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Adet")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.white.opacity(0.8))
                                FormattedNumberField(text: $quantity, placeholder: "0", allowDecimals: false, focusTrigger: $triggerQuantityFocus)
                                    .foregroundColor(.white)
                                    .padding(20)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.white.opacity(0.08))
                                    )
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { triggerQuantityFocus = true }
                            
                            // Güncel birim fiyat (hisse fiyatı güncellenince toplam otomatik güncellenir)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Güncel Birim Fiyat (₺)")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.white.opacity(0.8))
                                FormattedNumberField(text: $pricePerUnit, placeholder: "0,00", allowDecimals: true, focusTrigger: $triggerPriceFocus)
                                    .foregroundColor(.white)
                                    .padding(20)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.white.opacity(0.08))
                                    )
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { triggerPriceFocus = true }
                        } else {
                            // Toplam tutar
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Toplam Değer (₺)")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.white.opacity(0.8))
                                FormattedNumberField(text: $totalAmount, placeholder: "0,00", allowDecimals: true, focusTrigger: $triggerTotalFocus)
                                    .foregroundColor(.white)
                                    .padding(20)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.white.opacity(0.08))
                                    )
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { triggerTotalFocus = true }
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Varlığı Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color(hex: "0F172A"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                name = asset.name
                quantity = asset.quantity.map { formatNumber($0) } ?? ""
                pricePerUnit = asset.pricePerUnit.map { String(format: "%.2f", $0) } ?? ""
                totalAmount = asset.totalAmount.map { String(format: "%.2f", $0) } ?? ""
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "94A3B8"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "60A5FA"))
                }
            }
        }
    }
    
    private func saveChanges() {
        let nameTrimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !nameTrimmed.isEmpty else { return }
        
        let updatedAsset: Asset
        
        if isQuantityBased {
            guard let q = parseFormattedNumber(quantity),
                  let p = parseFormattedNumber(pricePerUnit),
                  q > 0, p >= 0 else { return }
            
            updatedAsset = Asset(
                id: asset.id,
                type: asset.type,
                typeName: asset.typeName,
                name: nameTrimmed,
                quantity: q,
                pricePerUnit: p,
                dateAdded: asset.dateAdded
            )
        } else {
            guard let amount = parseFormattedNumber(totalAmount),
                  amount > 0 else { return }
            
            updatedAsset = Asset(
                id: asset.id,
                type: asset.type,
                typeName: asset.typeName,
                name: nameTrimmed,
                totalAmount: amount,
                dateAdded: asset.dateAdded
            )
        }
        
        dataManager.updateAsset(updatedAsset)
        dismiss()
    }
}

#Preview {
    EditAssetView(asset: Asset(
        type: .stock,
        typeName: "Hisse Senedi",
        name: "THYAO",
        quantity: 100,
        pricePerUnit: 250
    ))
    .environmentObject(DataManager.shared)
}
