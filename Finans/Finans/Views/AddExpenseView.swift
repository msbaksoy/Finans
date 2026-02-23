import SwiftUI

struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var appTheme: AppTheme
    
    @State private var amount: String = ""
    @State private var selectedCategory: String = "Market"
    @State private var customCategory: String = ""
    @State private var detail: String = ""
    @State private var triggerAmountFocus = false
    @FocusState private var customCategoryFocused: Bool
    @FocusState private var detailFocused: Bool
    
    private var isOtherSelected: Bool { selectedCategory == "Diğer" }
    private var displayCategories: [String] {
        ExpenseCategory.allCases.map { $0.rawValue }.filter { $0 != "Diğer" } +
        dataManager.customExpenseCategories +
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
                        
                        // Kategori
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Kategori")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(appTheme.textSecondary)
                            
                            Menu {
                                ForEach(displayCategories, id: \.self) { category in
                                    Button(category) {
                                        selectedCategory = category
                                        if category != "Diğer" {
                                            customCategory = ""
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(selectedCategory)
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
                                TextField("Kategori adını girin (örn: Hobi)", text: $customCategory)
                                    .foregroundColor(appTheme.textPrimary)
                                    .padding(AppSpacing.lg)
                                    .background(
                                        RoundedRectangle(cornerRadius: AppSpacing.md)
                                            .fill(appTheme.formInputSecondary)
                                    )
                                    .focused($customCategoryFocused)
                            }
                        }
                        .tappableToFocus($customCategoryFocused)
                        
                        // Harcama detayı / açıklama
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Harcama Detayı")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(appTheme.textSecondary)
                            TextField("Açıklama veya detay girin (örn: Migros alışverişi)", text: $detail, axis: .vertical)
                                .lineLimit(3...6)
                                .foregroundColor(appTheme.textPrimary)
                                .padding(AppSpacing.lg)
                                .background(
                                    RoundedRectangle(cornerRadius: AppSpacing.lg)
                                        .fill(appTheme.formInputBackground)
                                )
                                .focused($detailFocused)
                        }
                        .tappableToFocus($detailFocused)
                    }
                    .padding(AppSpacing.xxl)
                }
            }
            .navigationTitle("Gider Ekle")
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
                        saveExpense()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "F87171"))
                }
            }
        }
    }
    
    private func saveExpense() {
        guard let amountValue = parseFormattedNumber(amount),
              amountValue > 0 else { return }
        
        guard !detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let category: String
        if isOtherSelected && !customCategory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            category = customCategory.trimmingCharacters(in: .whitespacesAndNewlines)
            dataManager.addCustomExpenseCategory(category)
        } else if isOtherSelected {
            return
        } else {
            category = selectedCategory
        }
        
        let expense = Expense(
            amount: amountValue,
            category: category,
            detail: detail.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        dataManager.addExpense(expense)
        dismiss()
    }
}

// MARK: - Gider Düzenle
struct EditExpenseView: View {
    let expense: Expense
    let onDismiss: () -> Void
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var appTheme: AppTheme
    
    @State private var amount: String = ""
    @State private var selectedCategory: String = "Market"
    @State private var customCategory: String = ""
    @State private var detail: String = ""
    @State private var triggerAmountFocus = false
    @FocusState private var customCategoryFocused: Bool
    @FocusState private var detailFocused: Bool
    
    private var isOtherSelected: Bool { selectedCategory == "Diğer" }
    private var displayCategories: [String] {
        ExpenseCategory.allCases.map(\.rawValue).filter { $0 != "Diğer" } +
        dataManager.customExpenseCategories + ["Diğer"]
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
                            Text("Kategori").font(.subheadline.weight(.medium)).foregroundColor(appTheme.textSecondary)
                            Menu {
                                ForEach(displayCategories, id: \.self) { category in
                                    Button(category) { selectedCategory = category; if category != "Diğer" { customCategory = "" } }
                                }
                            } label: {
                                HStack {
                                    Text(selectedCategory).foregroundColor(appTheme.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.down").foregroundColor(appTheme.textSecondary)
                                }
                                .padding(AppSpacing.xl).background(RoundedRectangle(cornerRadius: AppSpacing.lg).fill(appTheme.formInputBackground))
                            }
                            if isOtherSelected {
                                TextField("Kategori adını girin", text: $customCategory)
                                    .foregroundColor(appTheme.textPrimary).padding(AppSpacing.lg)
                                    .background(RoundedRectangle(cornerRadius: AppSpacing.md).fill(appTheme.formInputSecondary))
                                    .focused($customCategoryFocused)
                            }
                        }
                        .tappableToFocus($customCategoryFocused)
                        
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Harcama Detayı").font(.subheadline.weight(.medium)).foregroundColor(appTheme.textSecondary)
                            TextField("Açıklama veya detay", text: $detail, axis: .vertical)
                                .lineLimit(3...6).foregroundColor(appTheme.textPrimary).padding(AppSpacing.lg)
                                .background(RoundedRectangle(cornerRadius: AppSpacing.lg).fill(appTheme.formInputBackground))
                                .focused($detailFocused)
                        }
                        .tappableToFocus($detailFocused)
                    }
                    .padding(AppSpacing.xxl)
                }
            }
            .navigationTitle("Gider Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(appTheme.isLight ? .light : .dark, for: .navigationBar)
            .toolbarBackground(appTheme.background, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { onDismiss() }.foregroundColor(appTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") { saveExpense() }.fontWeight(.semibold).foregroundColor(Color(hex: "F87171"))
                }
            }
            .onAppear {
                amount = formatNumberGiris(String(format: "%.2f", expense.amount), allowDecimals: true)
                if ExpenseCategory.allCases.map(\.rawValue).contains(expense.category) {
                    selectedCategory = expense.category
                } else {
                    selectedCategory = "Diğer"
                    customCategory = expense.category
                }
                detail = expense.detail
            }
        }
    }
    
    private func saveExpense() {
        guard let amountValue = parseFormattedNumber(amount), amountValue > 0 else { return }
        guard !detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let category: String
        if isOtherSelected && !customCategory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            category = customCategory.trimmingCharacters(in: .whitespacesAndNewlines)
            dataManager.addCustomExpenseCategory(category)
        } else if isOtherSelected { return }
        else { category = selectedCategory }
        let updated = Expense(id: expense.id, amount: amountValue, category: category, detail: detail.trimmingCharacters(in: .whitespacesAndNewlines), date: expense.date)
        dataManager.updateExpense(updated)
        onDismiss()
    }
}

#Preview {
    AddExpenseView()
        .environmentObject(DataManager.shared)
        .environmentObject(AppTheme())
}
