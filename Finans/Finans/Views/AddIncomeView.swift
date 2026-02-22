import SwiftUI

struct AddIncomeView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager
    
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
                Color(hex: "0F172A").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Tutar
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tutar")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.white.opacity(0.8))
                            FormattedNumberField(text: $amount, placeholder: "0,00", allowDecimals: true, focusTrigger: $triggerAmountFocus, fontSize: 32, fontWeight: .semibold)
                                .foregroundColor(.white)
                                .padding(20)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.08))
                                )
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { triggerAmountFocus = true }
                        
                        // Kaynak seçimi
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Gelir Kaynağı")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.white.opacity(0.8))
                            
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
                                TextField("Kaynak adını girin (örn: Ek iş)", text: $customSource)
                                    .foregroundColor(.white)
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.06))
                                    )
                                    .focused($customSourceFocused)
                            }
                        }
                        .tappableToFocus($customSourceFocused)
                        
                        // Not (opsiyonel)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Not (opsiyonel)")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.white.opacity(0.8))
                            TextField("Açıklama...", text: $note, axis: .vertical)
                                .lineLimit(3...6)
                                .foregroundColor(.white)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.08))
                                )
                                .focused($noteFocused)
                        }
                        .tappableToFocus($noteFocused)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Gelir Ekle")
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
                Color(hex: "0F172A").ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tutar").font(.subheadline.weight(.medium)).foregroundColor(.white.opacity(0.8))
                            FormattedNumberField(text: $amount, placeholder: "0,00", allowDecimals: true, focusTrigger: $triggerAmountFocus, fontSize: 32, fontWeight: .semibold)
                                .foregroundColor(.white).padding(20)
                                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.08)))
                        }
                        .contentShape(Rectangle()).onTapGesture { triggerAmountFocus = true }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Gelir Kaynağı").font(.subheadline.weight(.medium)).foregroundColor(.white.opacity(0.8))
                            Menu {
                                ForEach(displaySources, id: \.self) { source in
                                    Button(source) { selectedSource = source; if source != "Diğer" { customSource = "" } }
                                }
                            } label: {
                                HStack {
                                    Text(selectedSource).foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.down").foregroundColor(.white.opacity(0.6))
                                }
                                .padding(20).background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.08)))
                            }
                            if isOtherSelected {
                                TextField("Kaynak adını girin", text: $customSource)
                                    .foregroundColor(.white).padding(16)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                                    .focused($customSourceFocused)
                            }
                        }
                        .tappableToFocus($customSourceFocused)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Not (opsiyonel)").font(.subheadline.weight(.medium)).foregroundColor(.white.opacity(0.8))
                            TextField("Açıklama...", text: $note, axis: .vertical)
                                .lineLimit(3...6).foregroundColor(.white).padding(16)
                                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.08)))
                                .focused($noteFocused)
                        }
                        .tappableToFocus($noteFocused)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Gelir Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color(hex: "0F172A"), for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { onDismiss() }.foregroundColor(Color(hex: "94A3B8"))
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
}
