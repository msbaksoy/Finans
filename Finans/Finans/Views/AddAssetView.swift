import SwiftUI

struct AddAssetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var appTheme: AppTheme
    
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
                appTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppSpacing.xxl) {
                        // Varlık türü
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Varlık Türü")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(appTheme.textSecondary)
                            
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
                                        .foregroundColor(appTheme.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(appTheme.textSecondary)
                                }
                                .padding(AppSpacing.xl)
                                .background(
                                    RoundedRectangle(cornerRadius: AppSpacing.lg)
                                        .fill(appTheme.formInputBackground)
                                )
                            }
                            
                            if isOtherSelected {
                                TextField("Varlık türünü girin (örn: Vadeli işlem)", text: $customTypeName)
                                    .foregroundColor(appTheme.textPrimary)
                                    .padding(AppSpacing.lg)
                                    .background(
                                        RoundedRectangle(cornerRadius: AppSpacing.md)
                                            .fill(appTheme.formInputSecondary)
                                    )
                                    .focused($customTypeFocused)
                            }
                        }
                        .tappableToFocus($customTypeFocused)
                        
                        // Ad / İsim
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text(isQuantityBased ? "Hisse / Varlık Adı" : "Hesap / Varlık Adı")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(appTheme.textSecondary)
                            TextField(isQuantityBased ? "Örn: THYAO, AAPL" : "Örn: Ziraat Vadeli Hesap", text: $name)
                                .foregroundColor(appTheme.textPrimary)
                                .padding(AppSpacing.xl)
                                .background(
                                    RoundedRectangle(cornerRadius: AppSpacing.lg)
                                        .fill(appTheme.formInputBackground)
                                )
                                .focused($nameFocused)
                        }
                        .tappableToFocus($nameFocused)
                        
                        if isQuantityBased {
                            // Adet
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Text("Adet")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(appTheme.textSecondary)
                                FormattedNumberField(text: $quantity, placeholder: "0", allowDecimals: false, focusTrigger: $triggerQuantityFocus, isLightMode: appTheme.isLight)
                                    .foregroundColor(appTheme.textPrimary)
                                    .padding(AppSpacing.xl)
                                    .background(
                                        RoundedRectangle(cornerRadius: AppSpacing.lg)
                                            .fill(appTheme.formInputBackground)
                                    )
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { triggerQuantityFocus = true }
                            
                            // Birim fiyat
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Text("Güncel Birim Fiyat (₺)")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(appTheme.textSecondary)
                                FormattedNumberField(text: $pricePerUnit, placeholder: "0,00", allowDecimals: true, focusTrigger: $triggerPriceFocus, isLightMode: appTheme.isLight)
                                    .foregroundColor(appTheme.textPrimary)
                                    .padding(AppSpacing.xl)
                                    .background(
                                        RoundedRectangle(cornerRadius: AppSpacing.lg)
                                            .fill(appTheme.formInputBackground)
                                    )
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { triggerPriceFocus = true }
                        } else {
                            // Toplam tutar
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Text("Toplam Değer (₺)")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(appTheme.textSecondary)
                                FormattedNumberField(text: $totalAmount, placeholder: "0,00", allowDecimals: true, focusTrigger: $triggerTotalFocus, isLightMode: appTheme.isLight)
                                    .foregroundColor(appTheme.textPrimary)
                                    .padding(AppSpacing.xl)
                                    .background(
                                        RoundedRectangle(cornerRadius: AppSpacing.lg)
                                            .fill(appTheme.formInputBackground)
                                    )
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { triggerTotalFocus = true }
                        }
                    }
                    .padding(AppSpacing.xxl)
                }
            }
            .navigationTitle("Varlık Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(appTheme.isLight ? .light : .dark, for: .navigationBar)
            .toolbarBackground(appTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        dismiss()
                    }
                    .foregroundColor(appTheme.textSecondary)
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
        .environmentObject(AppTheme())
}
