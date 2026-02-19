import SwiftUI

struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    
    @State private var amount: String = ""
    @State private var selectedCategory: String = "Market"
    @State private var customCategory: String = ""
    @State private var detail: String = ""
    
    private var isOtherSelected: Bool { selectedCategory == "Diğer" }
    private var displayCategories: [String] {
        ExpenseCategory.allCases.map { $0.rawValue }.filter { $0 != "Diğer" } +
        dataManager.customExpenseCategories +
        ["Diğer"]
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0F172A").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Tutar
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tutar")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.white.opacity(0.8))
                            TextField("0,00", text: $amount)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(20)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.08))
                                )
                        }
                        
                        // Kategori
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Kategori")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.white.opacity(0.8))
                            
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
                                TextField("Kategori adını girin (örn: Hobi)", text: $customCategory)
                                    .foregroundColor(.white)
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.06))
                                    )
                            }
                        }
                        
                        // Harcama detayı / açıklama
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Harcama Detayı")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.white.opacity(0.8))
                            TextField("Açıklama veya detay girin (örn: Migros alışverişi)", text: $detail, axis: .vertical)
                                .lineLimit(3...6)
                                .foregroundColor(.white)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.08))
                                )
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Gider Ekle")
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
                        saveExpense()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "F87171"))
                }
            }
        }
    }
    
    private func saveExpense() {
        guard let amountValue = Double(amount.replacingOccurrences(of: ",", with: ".")),
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

#Preview {
    AddExpenseView()
        .environmentObject(DataManager.shared)
}
