import Foundation

// MARK: - Gelir (Income)
struct Income: Identifiable, Codable {
    let id: UUID
    let amount: Double
    let source: String
    let date: Date
    let note: String?
    
    init(id: UUID = UUID(), amount: Double, source: String, date: Date = Date(), note: String? = nil) {
        self.id = id
        self.amount = amount
        self.source = source
        self.date = date
        self.note = note
    }
}

// MARK: - Gider (Expense)
struct Expense: Identifiable, Codable {
    let id: UUID
    let amount: Double
    let category: String
    let detail: String
    let date: Date
    
    init(id: UUID = UUID(), amount: Double, category: String, detail: String, date: Date = Date()) {
        self.id = id
        self.amount = amount
        self.category = category
        self.detail = detail
        self.date = date
    }
}

// MARK: - Sabit Gelir Kaynakları
enum IncomeSource: String, CaseIterable {
    case salary = "Maaş"
    case dividend = "Temettü"
    case bonus = "İkramiye"
    case rent = "Kira Geliri"
    case freelance = "Freelance"
    case investment = "Yatırım Getirisi"
    case other = "Diğer"
}

// MARK: - Sabit Gider Kategorileri
enum ExpenseCategory: String, CaseIterable {
    case clothing = "Giyim"
    case grocery = "Market"
    case fuel = "Akaryakıt"
    case housing = "Konut"
    case utilities = "Faturalar"
    case food = "Yemek"
    case transport = "Ulaşım"
    case health = "Sağlık"
    case entertainment = "Eğlence"
    case education = "Eğitim"
    case other = "Diğer"
}
