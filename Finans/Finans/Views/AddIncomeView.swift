import SwiftUI

struct AddIncomeView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var appTheme: AppTheme
    
    @State private var amount: String = ""
    @State private var selectedSource: String = "Maaş"
    @State private var customSource: String = ""
    @State private var note: String = ""
    @State private var showingSourcePicker = false
    @State private var triggerAmountFocus = false
    @FocusState private var customSourceFocused: Bool
    @FocusState private var noteFocused: Bool
    
    private var isOtherSelected: Bool { selectedSource == "Diğer" }
    private var displaySources: [String] {
        IncomeSource.allCases.map { $0.rawValue }.filter { $0 != "Diğer" } +
        dataManager.customIncomeSources +
        ["Diğer"]
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                appTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppSpacing.xxl) {
                        // Tutar
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Tutar")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(appTheme.textSecondary)
                            FormattedNumberField(text: $amount, placeholder: "0,00", allowDecimals: true, focusTrigger: $triggerAmountFocus, fontSize: 24, fontWeight: .semibold, isLightMode: appTheme.isLight)
                                .foregroundColor(appTheme.textPrimary)
                                .padding(AppSpacing.xl)
                                .background(
                                    RoundedRectangle(cornerRadius: AppSpacing.lg)
                                        .fill(appTheme.formInputBackground)
                                )
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { triggerAmountFocus = true }
                        
                        // Kaynak seçimi
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Gelir Kaynağı")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(appTheme.textSecondary)
                            
                            Menu {
                                ForEach(displaySources, id: \.self) { source in
                                    Button(source) {
                                        selectedSource = source
                                        if source != "Diğer" {
                                            customSource = ""
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(selectedSource)
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
                                TextField("Kaynak adını girin (örn: Ek iş)", text: $customSource)
                                    .foregroundColor(appTheme.textPrimary)
                                    .padding(AppSpacing.lg)
                                    .background(
                                        RoundedRectangle(cornerRadius: AppSpacing.md)
                                            .fill(appTheme.formInputSecondary)
                                    )
                                    .focused($customSourceFocused)
                            }
                        }
                        .tappableToFocus($customSourceFocused)
                        
                        // Not (opsiyonel)
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Not (opsiyonel)")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(appTheme.textSecondary)
                            TextField("Açıklama...", text: $note, axis: .vertical)
                                .lineLimit(3...6)
                                .foregroundColor(appTheme.textPrimary)
                                .padding(AppSpacing.lg)
                                .background(
                                    RoundedRectangle(cornerRadius: AppSpacing.lg)
                                        .fill(appTheme.formInputBackground)
                                )
                                .focused($noteFocused)
                        }
                        .tappableToFocus($noteFocused)
                    }
                    .padding(AppSpacing.xxl)
                }
            }
            .navigationTitle("Gelir Ekle")
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
                        saveIncome()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "34D399"))
                }
            }
        }
    }
    
    private func saveIncome() {
        guard let amountValue = parseFormattedNumber(amount),
              amountValue > 0 else { return }
        
        let source: String
        if isOtherSelected && !customSource.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            source = customSource.trimmingCharacters(in: .whitespacesAndNewlines)
            dataManager.addCustomIncomeSource(source)
        } else if isOtherSelected {
            return
        } else {
            source = selectedSource
        }
        
        let income = Income(
            amount: amountValue,
            source: source,
            note: note.isEmpty ? nil : note
        )
        dataManager.addIncome(income)
        dismiss()
    }
}

// MARK: - Gelir Düzenle
struct EditIncomeView: View {
    let income: Income
    let onDismiss: () -> Void
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var appTheme: AppTheme
    
    @State private var amount: String = ""
    @State private var selectedSource: String = "Maaş"
    @State private var customSource: String = ""
    @State private var note: String = ""
    @State private var triggerAmountFocus = false
    @FocusState private var customSourceFocused: Bool
    @FocusState private var noteFocused: Bool
    
    private var isOtherSelected: Bool { selectedSource == "Diğer" }
    private var displaySources: [String] {
        IncomeSource.allCases.map { $0.rawValue }.filter { $0 != "Diğer" } +
        dataManager.customIncomeSources +
        ["Diğer"]
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                appTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: AppSpacing.xxl) {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Tutar").font(.subheadline.weight(.medium)).foregroundColor(appTheme.textSecondary)
                            FormattedNumberField(text: $amount, placeholder: "0,00", allowDecimals: true, focusTrigger: $triggerAmountFocus, fontSize: 24, fontWeight: .semibold, isLightMode: appTheme.isLight)
                                .foregroundColor(appTheme.textPrimary).padding(AppSpacing.xl)
                                .background(RoundedRectangle(cornerRadius: AppSpacing.lg).fill(appTheme.formInputBackground))
                        }
                        .contentShape(Rectangle()).onTapGesture { triggerAmountFocus = true }
                        
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Gelir Kaynağı").font(.subheadline.weight(.medium)).foregroundColor(appTheme.textSecondary)
                            Menu {
                                ForEach(displaySources, id: \.self) { source in
                                    Button(source) { selectedSource = source; if source != "Diğer" { customSource = "" } }
                                }
                            } label: {
                                HStack {
                                    Text(selectedSource).foregroundColor(appTheme.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.down").foregroundColor(appTheme.textSecondary)
                                }
                                .padding(AppSpacing.xl).background(RoundedRectangle(cornerRadius: AppSpacing.lg).fill(appTheme.formInputBackground))
                            }
                            if isOtherSelected {
                                TextField("Kaynak adını girin", text: $customSource)
                                    .foregroundColor(appTheme.textPrimary).padding(AppSpacing.lg)
                                    .background(RoundedRectangle(cornerRadius: AppSpacing.md).fill(appTheme.formInputSecondary))
                                    .focused($customSourceFocused)
                            }
                        }
                        .tappableToFocus($customSourceFocused)
                        
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Not (opsiyonel)").font(.subheadline.weight(.medium)).foregroundColor(appTheme.textSecondary)
                            TextField("Açıklama...", text: $note, axis: .vertical)
                                .lineLimit(3...6).foregroundColor(appTheme.textPrimary).padding(AppSpacing.lg)
                                .background(RoundedRectangle(cornerRadius: AppSpacing.lg).fill(appTheme.formInputBackground))
                                .focused($noteFocused)
                        }
                        .tappableToFocus($noteFocused)
                    }
                    .padding(AppSpacing.xxl)
                }
            }
            .navigationTitle("Gelir Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(appTheme.isLight ? .light : .dark, for: .navigationBar)
            .toolbarBackground(appTheme.background, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { onDismiss() }.foregroundColor(appTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") { saveIncome() }.fontWeight(.semibold).foregroundColor(Color(hex: "34D399"))
                }
            }
            .onAppear {
                amount = formatNumberGiris(String(format: "%.2f", income.amount), allowDecimals: true)
                if IncomeSource.allCases.map(\.rawValue).contains(income.source) {
                    selectedSource = income.source
                } else if dataManager.customIncomeSources.contains(income.source) {
                    selectedSource = "Diğer"
                    customSource = income.source
                } else {
                    selectedSource = "Diğer"
                    customSource = income.source
                }
                note = income.note ?? ""
            }
        }
    }
    
    private func saveIncome() {
        guard let amountValue = parseFormattedNumber(amount), amountValue > 0 else { return }
        let source: String
        if isOtherSelected && !customSource.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            source = customSource.trimmingCharacters(in: .whitespacesAndNewlines)
            dataManager.addCustomIncomeSource(source)
        } else if isOtherSelected { return }
        else { source = selectedSource }
        let updated = Income(id: income.id, amount: amountValue, source: source, date: income.date, note: note.isEmpty ? nil : note)
        dataManager.updateIncome(updated)
        onDismiss()
    }
}

#Preview {
    AddIncomeView()
        .environmentObject(DataManager.shared)
        .environmentObject(AppTheme())
}
