import SwiftUI

struct BudgetView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showAddIncome = false
    @State private var showAddExpense = false
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            Color(hex: "0F172A").ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Özet Kartları
                    HStack(spacing: 16) {
                        SummaryCard(
                            title: "Toplam Gelir",
                            amount: dataManager.totalIncome,
                            icon: "arrow.down.circle.fill",
                            color: Color(hex: "34D399")
                        )
                        
                        SummaryCard(
                            title: "Toplam Gider",
                            amount: dataManager.totalExpense,
                            icon: "arrow.up.circle.fill",
                            color: Color(hex: "F87171")
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Bakiye
                    BalanceCard(amount: dataManager.balance)
                        .padding(.horizontal, 20)
                    
                    // Ekle butonları
                    HStack(spacing: 12) {
                        ActionButton(
                            title: "Gelir Ekle",
                            icon: "plus.circle.fill",
                            color: Color(hex: "34D399")
                        ) {
                            showAddIncome = true
                        }
                        
                        ActionButton(
                            title: "Gider Ekle",
                            icon: "minus.circle.fill",
                            color: Color(hex: "F87171")
                        ) {
                            showAddExpense = true
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Segmented Control - Gelir / Gider listesi
                    Picker("", selection: $selectedTab) {
                        Text("Gelirler").tag(0)
                        Text("Giderler").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    
                    // Liste - ScrollView içinde LazyVStack kullanıyoruz (List yerine)
                    if selectedTab == 0 {
                        IncomeListView()
                    } else {
                        ExpenseListView()
                    }
                }
                .padding(.vertical, 24)
            }
        }
        .navigationTitle("Bütçe")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color(hex: "0F172A"), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $showAddIncome) {
            AddIncomeView()
        }
        .sheet(isPresented: $showAddExpense) {
            AddExpenseView()
        }
    }
}

struct SummaryCard: View {
    let title: String
    let amount: Double
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            Text(formatCurrency(amount))
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct BalanceCard: View {
    let amount: Double
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Bakiye")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                Text(formatCurrency(amount))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(amount >= 0 ? Color(hex: "34D399") : Color(hex: "F87171"))
            }
            Spacer()
            Image(systemName: "wallet.pass.fill")
                .font(.system(size: 36))
                .foregroundColor(.white.opacity(0.2))
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "1E293B"),
                            Color(hex: "334155")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(hex: "34D399").opacity(0.5),
                                    Color(hex: "10B981").opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(color)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct IncomeListView: View {
    @EnvironmentObject var dataManager: DataManager
    
    private var sortedIncomes: [Income] {
        dataManager.incomes.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        Group {
            if dataManager.incomes.isEmpty {
                EmptyStateView(
                    icon: "arrow.down.circle",
                    message: "Henüz gelir eklenmedi",
                    submessage: "Yukarıdaki butondan gelir ekleyebilirsiniz"
                )
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(sortedIncomes) { income in
                        IncomeRowView(income: income)
                            .contextMenu {
                                Button(role: .destructive) {
                                    if let idx = dataManager.incomes.firstIndex(where: { $0.id == income.id }) {
                                        dataManager.incomes.remove(at: idx)
                                        dataManager.saveIncomesIfNeeded()
                                    }
                                } label: {
                                    Label("Sil", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct IncomeRowView: View {
    let income: Income
    
    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "34D399").opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(Color(hex: "34D399"))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(income.source)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Text(income.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            Text(formatCurrency(income.amount))
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: "34D399"))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
        )
    }
}

struct ExpenseListView: View {
    @EnvironmentObject var dataManager: DataManager
    
    private var sortedExpenses: [Expense] {
        dataManager.expenses.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        Group {
            if dataManager.expenses.isEmpty {
                EmptyStateView(
                    icon: "arrow.up.circle",
                    message: "Henüz gider eklenmedi",
                    submessage: "Yukarıdaki butondan gider ekleyebilirsiniz"
                )
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(sortedExpenses) { expense in
                        ExpenseRowView(expense: expense)
                            .contextMenu {
                                Button(role: .destructive) {
                                    if let idx = dataManager.expenses.firstIndex(where: { $0.id == expense.id }) {
                                        dataManager.expenses.remove(at: idx)
                                        dataManager.saveExpensesIfNeeded()
                                    }
                                } label: {
                                    Label("Sil", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ExpenseRowView: View {
    let expense: Expense
    
    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "F87171").opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(Color(hex: "F87171"))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.category)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Text(expense.detail)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
                Text(expense.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            Text("-\(formatCurrency(expense.amount))")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: "F87171"))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
        )
    }
}

struct EmptyStateView: View {
    let icon: String
    let message: String
    let submessage: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.3))
            Text(message)
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
            Text(submessage)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}

/// Anapara girişinde binlik ayracı (nokta) ile formatlama: 200000 → 200.000
func formatAnaparaGiris(_ raw: String) -> String {
    let digits = raw.filter { $0.isNumber }
    guard !digits.isEmpty else { return "" }
    let trimmed = digits.drop(while: { $0 == "0" })
    let str = trimmed.isEmpty ? "0" : String(trimmed)
    var result = ""
    for (i, c) in str.reversed().enumerated() {
        if i > 0 && i % 3 == 0 { result = "." + result }
        result = String(c) + result
    }
    return result
}

func formatCurrency(_ amount: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = Locale(identifier: "tr_TR")
    formatter.maximumFractionDigits = 2
    formatter.minimumFractionDigits = 2
    return formatter.string(from: NSNumber(value: amount)) ?? "₺0,00"
}

#Preview {
    NavigationStack {
        BudgetView()
            .environmentObject(DataManager.shared)
    }
}
