import SwiftUI
import UIKit

struct BudgetView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var appTheme: AppTheme
    @State private var showAddIncome = false
    @State private var showAddExpense = false
    @State private var selectedTab = 0
    @State private var showPdfShare = false
    @State private var pdfData: Data?
    @State private var editingIncome: Income?
    @State private var editingExpense: Expense?
    
    var body: some View {
        ZStack {
            appTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Kompakt özet
                HStack(spacing: AppSpacing.sm) {
                    SummaryCard(title: "Gelir", amount: dataManager.totalIncome, icon: "arrow.down.circle.fill", color: Color(hex: "34D399"))
                    SummaryCard(title: "Gider", amount: dataManager.totalExpense, icon: "arrow.up.circle.fill", color: Color(hex: "F87171"))
                }
                .padding(.horizontal, AppSpacing.xxl)
                .padding(.top, AppSpacing.md)
                BalanceCard(amount: dataManager.balance)
                    .padding(.horizontal, AppSpacing.xxl)
                    .padding(.vertical, AppSpacing.sm)
                
                // Ekle butonları + Segment
                HStack(spacing: AppSpacing.sm) {
                    ActionButton(title: "Gelir Ekle", icon: "plus.circle.fill", color: Color(hex: "34D399"), style: .primary) { showAddIncome = true }
                    ActionButton(title: "Gider Ekle", icon: "minus.circle.fill", color: Color(hex: "F87171"), style: .secondary) { showAddExpense = true }
                }
                .padding(.horizontal, AppSpacing.xxl)
                .padding(.bottom, AppSpacing.md)
                
                HStack(spacing: 0) {
                    BudgetSegmentButton(title: "Gelirler", isSelected: selectedTab == 0) {
                        selectedTab = 0
                    }
                    BudgetSegmentButton(title: "Giderler", isSelected: selectedTab == 1) {
                        selectedTab = 1
                    }
                }
                .padding(AppSpacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(appTheme.isLight ? Color(hex: "E2E8F0") : Color(hex: "334155"))
                )
                .padding(.horizontal, AppSpacing.xxl)
                .padding(.bottom, AppSpacing.md)
                
                // Liste – kalan alanı doldur
                Group {
                    if selectedTab == 0 {
                        IncomeListView(editingIncome: $editingIncome)
                            .transition(.opacity.combined(with: .move(edge: .leading)))
                    } else {
                        ExpenseListView(editingExpense: $editingExpense)
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: selectedTab)
            }
        }
        .navigationTitle("Bütçe")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(appTheme.isLight ? .light : .dark, for: .navigationBar)
        .toolbarBackground(appTheme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $showAddIncome) {
            AddIncomeView().environmentObject(appTheme)
        }
        .sheet(isPresented: $showAddExpense) {
            AddExpenseView().environmentObject(appTheme)
        }
        .sheet(item: $editingIncome) { income in
            EditIncomeView(income: income) {
                editingIncome = nil
            }
            .environmentObject(appTheme)
        }
        .sheet(item: $editingExpense) { expense in
            EditExpenseView(expense: expense) {
                editingExpense = nil
            }
            .environmentObject(appTheme)
        }
        .sheet(isPresented: $showPdfShare) {
            if let data = pdfData {
                PdfShareSheet(pdfData: data)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    if let data = BudgetPdfOlusturucu.olustur(incomes: dataManager.incomes, expenses: dataManager.expenses) {
                        pdfData = data
                        showPdfShare = true
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }
}

struct BudgetSegmentButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var appTheme: AppTheme
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.25)) {
                action()
            }
        }) {
            Text(title)
                .font(AppTypography.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? .white : appTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? Color(hex: "34D399") : Color.clear)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct SummaryCard: View {
    let title: String
    let amount: Double
    let icon: String
    let color: Color
    @EnvironmentObject var appTheme: AppTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                Text(title)
                    .font(AppTypography.subheadline)
                    .foregroundColor(appTheme.textSecondary)
            }
            Text(formatCurrency(amount))
                .font(AppTypography.amountSmall)
                .monospacedDigit()
                .contentTransition(.numericText())
                .foregroundColor(appTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(appTheme.listRowBackground)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.25), lineWidth: 0.5))
                .shadow(color: .black.opacity(appTheme.isLight ? 0.03 : 0), radius: appTheme.isLight ? 8 : 0, y: 4)
        )
    }
}

struct BalanceCard: View {
    let amount: Double
    @EnvironmentObject var appTheme: AppTheme
    
    var body: some View {
        HStack {
            Text("Bakiye")
                .font(AppTypography.subheadline)
                .foregroundColor(appTheme.textSecondary)
            Spacer()
            Text(formatCurrency(amount))
                .font(AppTypography.amountMedium)
                .monospacedDigit()
                .contentTransition(.numericText())
                .foregroundColor(amount >= 0 ? Color(hex: "34D399") : Color(hex: "F87171"))
        }
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(appTheme.listRowBackground)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "34D399").opacity(0.25), lineWidth: 0.5))
                .shadow(color: .black.opacity(appTheme.isLight ? 0.03 : 0), radius: appTheme.isLight ? 8 : 0, y: 4)
        )
    }
}

enum ActionButtonStyle {
    case primary
    case secondary
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    var style: ActionButtonStyle = .primary
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(title)
                    .font(AppTypography.headline)
            }
            .foregroundColor(style == .primary ? .white : color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                Group {
                    if style == .primary {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(color)
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(color, lineWidth: 2)
                            )
                    }
                }
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct IncomeListView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var appTheme: AppTheme
    @Binding var editingIncome: Income?
    
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
                .padding(.vertical, 24)
            } else {
                List {
                    ForEach(sortedIncomes) { income in
                        IncomeRowView(income: income)
                            .transition(.opacity.combined(with: .move(edge: .leading)))
                            .listRowBackground(appTheme.listRowBackground)
                            .listRowSeparatorTint(appTheme.textSecondary.opacity(0.3))
                            .contentShape(Rectangle())
                            .onTapGesture { editingIncome = income }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
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
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .padding(.horizontal, AppSpacing.xxl)
    }
}

struct IncomeRowView: View {
    let income: Income
    @EnvironmentObject var appTheme: AppTheme
    
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
                    .foregroundColor(appTheme.textPrimary)
                Text(income.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(appTheme.textSecondary)
            }
            
            Spacer()
            
            Text(formatCurrency(income.amount))
                .font(AppTypography.amountSmall)
                .monospacedDigit()
                .contentTransition(.numericText())
                .foregroundColor(Color(hex: "34D399"))
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(appTheme.cardBackgroundSecondary)
                .shadow(color: .black.opacity(appTheme.isLight ? 0.03 : 0), radius: appTheme.isLight ? 8 : 0, y: 4)
        )
    }
}

struct ExpenseListView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var appTheme: AppTheme
    @Binding var editingExpense: Expense?
    
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
                .padding(.vertical, 24)
            } else {
                List {
                    ForEach(sortedExpenses) { expense in
                        ExpenseRowView(expense: expense)
                            .transition(.opacity.combined(with: .move(edge: .leading)))
                            .listRowBackground(appTheme.listRowBackground)
                            .listRowSeparatorTint(appTheme.textSecondary.opacity(0.3))
                            .contentShape(Rectangle())
                            .onTapGesture { editingExpense = expense }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
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
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .padding(.horizontal, AppSpacing.xxl)
    }
}

struct ExpenseRowView: View {
    let expense: Expense
    @EnvironmentObject var appTheme: AppTheme
    
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
                    .foregroundColor(appTheme.textPrimary)
                Text(expense.detail)
                    .font(.caption)
                    .foregroundColor(appTheme.textSecondary)
                    .lineLimit(1)
                Text(expense.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundColor(appTheme.textSecondary.opacity(0.9))
            }
            
            Spacer()
            
            Text("-\(formatCurrency(expense.amount))")
                .font(AppTypography.amountSmall)
                .monospacedDigit()
                .contentTransition(.numericText())
                .foregroundColor(Color(hex: "F87171"))
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(appTheme.cardBackgroundSecondary)
                .shadow(color: .black.opacity(appTheme.isLight ? 0.03 : 0), radius: appTheme.isLight ? 8 : 0, y: 4)
        )
    }
}

struct EmptyStateView: View {
    let icon: String
    let message: String
    let submessage: String
    @EnvironmentObject var appTheme: AppTheme
    @State private var appeared = false
    
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            ZStack {
                Circle()
                    .fill(appTheme.listRowBackground)
                    .frame(width: 88, height: 88)
                Image(systemName: icon)
                    .font(AppTypography.title1)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                appTheme.textSecondary.opacity(0.8),
                                appTheme.textSecondary.opacity(0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .scaleEffect(appeared ? 1 : 0.9)
            .opacity(appeared ? 1 : 0)
            VStack(spacing: AppSpacing.sm) {
                Text(message)
                    .font(AppTypography.headline)
                    .foregroundColor(appTheme.textPrimary)
                Text(submessage)
                    .font(.subheadline)
                    .foregroundColor(appTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.xxl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(message). \(submessage)")
        .onAppear {
            withAnimation(.easeOut(duration: 0.35)) {
                appeared = true
            }
        }
    }
}

/// Rakam girişinde binlik ayracı (nokta) ile formatlama: 200000 → 200.000
/// allowDecimals: true ise virgülden sonra en fazla 2 hane (1.500,50)
func formatNumberGiris(_ raw: String, allowDecimals: Bool = false) -> String {
    if !allowDecimals {
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
    // Türk formatı: binlik = nokta (.), ondalık = virgül (,) veya nokta (faiz gibi 4.99)
    // Virgül varsa ondalık ayracı virgül. Virgül yoksa: nokta sonrası 1–2 rakamsa ondalık (4.99)
    var intStr: String
    var decStr: String
    if raw.contains(",") {
        let parts = raw.split(separator: ",", maxSplits: 1, omittingEmptySubsequences: false)
        let intRaw = String(parts[0])
        intStr = intRaw.replacingOccurrences(of: ".", with: "").filter { $0.isNumber }
        decStr = parts.count > 1 ? String(String(parts[1]).filter { $0.isNumber }.prefix(2)) : ""
    } else if let lastDot = raw.lastIndex(of: ".") {
        let afterDot = String(raw[raw.index(after: lastDot)...]).filter { $0.isNumber }
        // Nokta sonrası 0–2 rakamsa ondalık (4. veya 4.9 veya 4.99), 3+ ise binlik (1.000)
        if afterDot.count <= 2 {
            let beforeDot = String(raw[..<lastDot]).replacingOccurrences(of: ".", with: "").filter { $0.isNumber }
            intStr = beforeDot
            decStr = String(afterDot.prefix(2))
        } else {
            intStr = raw.replacingOccurrences(of: ".", with: "").filter { $0.isNumber }
            decStr = ""
        }
    } else {
        intStr = raw.replacingOccurrences(of: ".", with: "").filter { $0.isNumber }
        decStr = ""
    }
    guard !intStr.isEmpty || !decStr.isEmpty else { return "" }
    let intPart = intStr.isEmpty ? "0" : String(intStr.drop(while: { $0 == "0" })).isEmpty ? "0" : String(intStr.drop(while: { $0 == "0" }))
    let trimmed = intPart.isEmpty ? "0" : intPart
    var result = ""
    for (i, c) in trimmed.reversed().enumerated() {
        if i > 0 && i % 3 == 0 { result = "." + result }
        result = String(c) + result
    }
    // Ondalık kısmı ekle; virgülden sonra boş olsa bile (kullanıcı "4." yazdıysa "4," göster)
    let hasTrailingDecimalSep = allowDecimals && (raw.hasSuffix(".") || raw.hasSuffix(","))
    if !decStr.isEmpty || hasTrailingDecimalSep {
        result += "," + decStr
    }
    return result
}

/// Anapara için (geriye uyumluluk)
func formatAnaparaGiris(_ raw: String) -> String {
    formatNumberGiris(raw, allowDecimals: false)
}

/// Formatlanmış rakam string'ini Double'a çevirir (1.500,50 → 1500.50)
func parseFormattedNumber(_ s: String) -> Double? {
    let cleaned = s.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
    return Double(cleaned)
}

/// Rakam girişinde yazarken binlik/ondalık formatlama uygulayan alan
struct FormattedNumberField: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let allowDecimals: Bool
    @Binding var focusTrigger: Bool
    var fontSize: CGFloat = 17
    var fontWeight: UIFont.Weight = .regular
    var isLightMode: Bool = false
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    func makeUIView(context: Context) -> UITextField {
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.font = .systemFont(ofSize: fontSize, weight: fontWeight)
        tf.keyboardType = allowDecimals ? .decimalPad : .numberPad
        tf.delegate = context.coordinator
        tf.textColor = isLightMode ? .label : .white
        tf.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        context.coordinator.syncFromBinding(to: tf)
        return tf
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        context.coordinator.parent = self
        if uiView.text != text && !context.coordinator.isEditing {
            context.coordinator.syncFromBinding(to: uiView)
        }
        uiView.textColor = isLightMode ? .label : .white
        if focusTrigger {
            uiView.becomeFirstResponder()
            DispatchQueue.main.async { focusTrigger = false }
        }
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: FormattedNumberField
        var isEditing = false
        
        init(_ parent: FormattedNumberField) { self.parent = parent }
        
        func syncFromBinding(to tf: UITextField) {
            let formatted = formatNumberGiris(parent.text, allowDecimals: parent.allowDecimals)
            if tf.text != formatted { tf.text = formatted }
        }
        
        func textFieldDidBeginEditing(_ textField: UITextField) { isEditing = true }
        func textFieldDidEndEditing(_ textField: UITextField) { isEditing = false }
        
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let current = textField.text ?? ""
            let ns = current as NSString
            let proposed = ns.replacingCharacters(in: range, with: string)
            let formatted = formatNumberGiris(proposed, allowDecimals: parent.allowDecimals)
            textField.text = formatted
            parent.text = formatted
            return false
        }
    }
}

func formatCurrency(_ amount: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = Locale(identifier: "tr_TR")
    formatter.maximumFractionDigits = 2
    formatter.minimumFractionDigits = 2
    return formatter.string(from: NSNumber(value: amount)) ?? "₺0,00"
}

// MARK: - Geniş tıklama alanı (tüm alana tıklanınca focus)
// Yeni TextField'larda kullan: VStack { Text("Başlık"); TextField(...).focused($focused) }.tappableToFocus($focused)
extension View {
    func tappableToFocus(_ focus: FocusState<Bool>.Binding) -> some View {
        contentShape(Rectangle())
            .onTapGesture { focus.wrappedValue = true }
    }
    func tappableToFocus<ID: Hashable>(_ focus: FocusState<ID?>.Binding, equals value: ID) -> some View {
        contentShape(Rectangle())
            .onTapGesture { focus.wrappedValue = value }
    }
}

#Preview {
    NavigationStack {
        BudgetView()
            .environmentObject(DataManager.shared)
            .environmentObject(AppTheme())
    }
}
