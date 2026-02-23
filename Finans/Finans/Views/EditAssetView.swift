import SwiftUI

struct EditAssetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var appTheme: AppTheme
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
                appTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppSpacing.xxl) {
                        // Tür (sadece gösterim)
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Varlık Türü")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(appTheme.textSecondary)
                            Text(asset.displayType)
                                .font(.body)
                                .foregroundColor(appTheme.textPrimary)
                                .padding(AppSpacing.xl)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: AppSpacing.lg)
                                        .fill(appTheme.formInputSecondary)
                                )
                        }
                        
                        // Ad
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Ad")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(appTheme.textSecondary)
                            TextField("Ad", text: $name)
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
                            
                            // Güncel birim fiyat
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
            .navigationTitle("Varlığı Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(appTheme.isLight ? .light : .dark, for: .navigationBar)
            .toolbarBackground(appTheme.background, for: .navigationBar)
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
                    .foregroundColor(appTheme.textSecondary)
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
    .environmentObject(AppTheme())
}
