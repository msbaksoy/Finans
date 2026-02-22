import SwiftUI

struct AddAssetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    @State private var selectedType: String = "Hisse Senedi"
    @State private var customTypeName: String = ""
    @State private var name: String = ""
    @State private var quantity: String = ""
    @State private var pricePerUnit: String = ""
    @State private var totalAmount: String = ""
    @FocusState private var customTypeFocused: Bool
    @FocusState private var nameFocused: Bool
    @State private var triggerQuantityFocus = false
    @State private var triggerPriceFocus = false
    @State private var triggerTotalFocus = false
    
    private var isOtherSelected: Bool { selectedType == "Diğer" }
    private var isQuantityBased: Bool {
        let type = assetTypeFromString(selectedType)
        return type?.supportsQuantityAndPrice ?? false
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0F172A").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Varlık türü
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Varlık Türü")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.white.opacity(0.8))
                            
                            Menu {
                                ForEach(dataManager.allAssetTypes, id: \.self) { type in
                                    Button(type) {
                                        selectedType = type
                                        if type != "Diğer" { customTypeName = "" }
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(selectedType)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                .padding(20)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.08))
                                )
                            }
                            
                            if isOtherSelected {
                                TextField("Varlık türünü girin (örn: Vadeli işlem)", text: $customTypeName)
                                    .foregroundColor(.white)
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.06))
                                    )
                                    .focused($customTypeFocused)
                            }
                        }
                        .tappableToFocus($customTypeFocused)
                        
                        // Ad / İsim
                        VStack(alignment: .leading, spacing: 8) {
                            Text(isQuantityBased ? "Hisse / Varlık Adı" : "Hesap / Varlık Adı")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.white.opacity(0.8))
                            TextField(isQuantityBased ? "Örn: THYAO, AAPL" : "Örn: Ziraat Vadeli Hesap", text: $name)
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
                            
                            // Birim fiyat
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
            .navigationTitle("Varlık Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color(hex: "0F172A"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "94A3B8"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        saveAsset()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "60A5FA"))
                }
            }
        }
    }
    
    private func saveAsset() {
        let type: AssetType
        let typeName: String
        
        if isOtherSelected {
            let trimmed = customTypeName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            type = .other
            typeName = trimmed
            dataManager.addCustomAssetType(trimmed)
        } else {
            guard let t = assetTypeFromString(selectedType) else { return }
            type = t
            typeName = selectedType
        }
        
        let nameTrimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !nameTrimmed.isEmpty else { return }
        
        if isQuantityBased {
            guard let q = parseFormattedNumber(quantity),
                  let p = parseFormattedNumber(pricePerUnit),
                  q > 0, p >= 0 else { return }
            
            let asset = Asset(type: type, typeName: typeName, name: nameTrimmed, quantity: q, pricePerUnit: p)
            dataManager.addAsset(asset)
        } else {
            guard let amount = parseFormattedNumber(totalAmount),
                  amount > 0 else { return }
            
            let asset = Asset(type: type, typeName: typeName, name: nameTrimmed, totalAmount: amount)
            dataManager.addAsset(asset)
        }
        
        dismiss()
    }
    
    private func assetTypeFromString(_ s: String) -> AssetType? {
        AssetType.allCases.first { $0.rawValue == s }
    }
}

#Preview {
    AddAssetView()
        .environmentObject(DataManager.shared)
}
