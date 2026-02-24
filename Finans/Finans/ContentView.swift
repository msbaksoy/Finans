import SwiftUI

private enum NavTarget: Hashable {
    case budget, portfolio, brutNet, kredi
}

enum WorkModel: String, CaseIterable {
    case remote = "Remote"
    case office = "Ofis"
    case hybrid = "Hibrit"
    var icon: String {
        switch self {
        case .remote: return "🏠"
        case .office: return "🏢"
        case .hybrid: return "💻"
        }
    }
    var displayName: String { rawValue }
}

struct ContentView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var appTheme: AppTheme
    @State private var navPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navPath) {
            ZStack {
                // Arka plan — çok katmanlı gradient
                girisArkaPlani
                
                // Ana ekran: yeni Dashboard
                VStack(spacing: 0) {
                    heroSection
                        .padding(.top, AppSpacing.lg)
                        .padding(.bottom, AppSpacing.md)

                    // DashboardView (modüler, hikâye odaklı ana ekran)
                    DashboardView()
                        .environmentObject(dataManager)
                        .environmentObject(appTheme)
                        .environmentObject(YanHakKayitStore.shared)
                        .padding(.top, AppSpacing.md)

                    Spacer(minLength: 0)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(appTheme.isLight ? Color(hex: "F8FAFC") : Color(hex: "0F172A"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ThemeToggleButton()
                }
            }
            .navigationDestination(for: NavTarget.self) { target in
                switch target {
                case .budget: BudgetView()
                case .portfolio: PortfolioView()
                case .brutNet: BrutNetView()
                case .kredi: KrediHesaplamaView()
                }
            }
        }
        .onAppear {
            dataManager.brutNetVerileriniTemizle()
        }
    }
    
    private var girisArkaPlani: some View {
        ZStack {
            if appTheme.isLight {
                LinearGradient(
                    colors: [
                        Color(hex: "F8FAFC"),
                        Color(hex: "F1F5F9")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "34D399").opacity(0.04),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 200
                        )
                    )
                    .frame(width: 300, height: 300)
                    .offset(x: 80, y: -100)
            } else {
                LinearGradient(
                    colors: [
                        Color(hex: "0F172A"),
                        Color(hex: "0c1220")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "34D399").opacity(0.06),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 200
                        )
                    )
                    .frame(width: 320, height: 320)
                    .blur(radius: 40)
                    .offset(x: 80, y: -80)
            }
        }
        .ignoresSafeArea()
    }
    
    private var heroSection: some View {
        VStack(spacing: 12) {
            // Logo container — cam efekti
            ZStack {
                Circle()
                    .fill(
                        appTheme.isLight
                            ? LinearGradient(
                                colors: [
                                    Color(hex: "34D399").opacity(0.2),
                                    Color(hex: "10B981").opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [
                                    Color(hex: "34D399").opacity(0.3),
                                    Color(hex: "0F172A")
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .frame(width: 64, height: 64)
                    .overlay(
                        Circle()
                            .stroke(Color(hex: "34D399").opacity(0.3), lineWidth: 0.5)
                    )
                    .shadow(color: Color(hex: "34D399").opacity(appTheme.isLight ? 0.1 : 0.2), radius: 12, y: 4)
                
                Image(systemName: "chart.pie.fill")
                    .font(AppTypography.title1)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "34D399"), Color(hex: "10B981")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            Text("Finans")
                .font(AppTypography.title1)
                .foregroundColor(appTheme.textPrimary)
            
            Text("Finansal yolculuğunuza hoş geldiniz")
                .font(AppTypography.callout)
                .foregroundColor(appTheme.textSecondary)
        }
    }
}

// Small button view for work model selection to simplify ViewBuilder expressions
fileprivate struct WorkModelButton: View {
    @EnvironmentObject var appTheme: AppTheme
    let model: WorkModel
    let selected: Bool
    let selectedColors: [Color]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                // base background
                RoundedRectangle(cornerRadius: 10)
                    .fill(appTheme.cardBackgroundSecondary)
                // selected gradient overlay
                if selected {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(colors: selectedColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                }
                VStack(spacing: 4) {
                    Text(model.icon).font(.title)
                    Text(model.displayName).font(AppTypography.caption2)
                }
                .foregroundColor(selected ? .white : appTheme.textPrimary)
            }
            .frame(minWidth: 64, minHeight: 64)
            .padding(4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tema Değiştirici — Şık kapsül buton
struct ThemeToggleButton: View {
    @EnvironmentObject var appTheme: AppTheme
    
    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                appTheme.toggle()
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(appTheme.isLight ? Color.white.opacity(0.9) : Color(hex: "1E293B").opacity(0.5))
                    .frame(width: 40, height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(appTheme.cardStroke.opacity(0.3), lineWidth: 0.5)
                    )
                Image(systemName: appTheme.isLight ? "moon.fill" : "sun.max.fill")
                    .font(AppTypography.callout)
                    .foregroundStyle(
                        appTheme.isLight
                            ? LinearGradient(colors: [Color(hex: "475569"), Color(hex: "64748B")], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color(hex: "FBBF24"), Color(hex: "F59E0B")], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Premium Menü Kartı — Modern, şık
struct PremiumMenuCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let accentColor: Color
    let accentSecondary: Color
    let action: () -> Void
    
    @EnvironmentObject var appTheme: AppTheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xl) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(accentColor.opacity(appTheme.isLight ? 0.15 : 0.25))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(AppTypography.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [accentColor, accentSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .shadow(color: accentColor.opacity(appTheme.isLight ? 0.06 : 0.12), radius: 12, y: 4)
                
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(title)
                        .font(AppTypography.headline)
                        .foregroundColor(appTheme.textPrimary)
                    Text(subtitle)
                        .font(AppTypography.footnote)
                        .foregroundColor(appTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Image(systemName: "chevron.right")
                    .font(AppTypography.footnote.weight(.semibold))
                    .foregroundColor(appTheme.textSecondary.opacity(0.7))
            }
            .padding(AppSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        appTheme.isLight
                            ? Color.white
                            : Color(hex: "1E293B").opacity(0.6)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                appTheme.isLight
                                    ? Color(hex: "E2E8F0").opacity(0.8)
                                    : Color.white.opacity(0.06),
                                lineWidth: 0.5
                            )
                    )
                    .shadow(
                        color: .black.opacity(appTheme.isLight ? 0.03 : 0.12),
                        radius: 12,
                        y: 4
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}


struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeInOut(duration: 0.16), value: configuration.isPressed)
            // minimum hit area for accessibility
            .padding(.vertical, 6)
            .contentShape(Rectangle())
    }
}

// Placeholder view for future Kıyaslama development
fileprivate struct KiyaslamaView: View {
    @EnvironmentObject var appTheme: AppTheme

    @State private var currentText: String = ""
    @State private var currentIsBrut: Bool = true
    @State private var currentMaasPeriyodu: Int = 12
    @State private var currentPrimText: String = ""
    @State private var currentPrimIsBrut: Bool = true
    @State private var currentCompany: String = ""

    @State private var offerText: String = ""
    @State private var offerIsBrut: Bool = true
    @State private var offerMaasPeriyodu: Int = 12
    @State private var offerPrimText: String = ""
    @State private var offerPrimIsBrut: Bool = true
    @State private var offerCompany: String = ""

    @State private var showResults: Bool = false
    @State private var currentMonthlyNets: [Double] = Array(repeating: 0, count: 12)
    @State private var offerMonthlyNets: [Double] = Array(repeating: 0, count: 12)
    @State private var currentSalaryOnlyMonthlyNets: [Double] = Array(repeating: 0, count: 12)
    @State private var offerSalaryOnlyMonthlyNets: [Double] = Array(repeating: 0, count: 12)
    @State private var navigateToCommute: Bool = false
    
    // Question 2 (work & commute) moved to a separate step view (KiyaslamaCommuteView)

    var body: some View {
        // Precompute scenario values (must be outside ViewBuilder)
        let currentSalarySum = currentSalaryOnlyMonthlyNets.reduce(0, +)
        let currentWithPrimSum = currentMonthlyNets.reduce(0, +)
        let offerSalarySum = offerSalaryOnlyMonthlyNets.reduce(0, +)
        let offerWithPrimSum = offerMonthlyNets.reduce(0, +)
        let currentHasPrim = abs(currentWithPrimSum - currentSalarySum) > 1.0
        let offerHasPrim = abs(offerWithPrimSum - offerSalarySum) > 1.0
        let anyPrim = currentHasPrim || offerHasPrim
        let currentSalaryOnlyAvg = currentSalaryOnlyMonthlyNets.isEmpty ? 0 : currentSalaryOnlyMonthlyNets.reduce(0, +) / Double(currentSalaryOnlyMonthlyNets.count)
        let offerSalaryOnlyAvg = offerSalaryOnlyMonthlyNets.isEmpty ? 0 : offerSalaryOnlyMonthlyNets.reduce(0, +) / Double(offerSalaryOnlyMonthlyNets.count)
        let currentWithPrimAvg = currentMonthlyNets.isEmpty ? 0 : currentMonthlyNets.reduce(0, +) / Double(currentMonthlyNets.count)
        let offerWithPrimAvg = offerMonthlyNets.isEmpty ? 0 : offerMonthlyNets.reduce(0, +) / Double(offerMonthlyNets.count)

        let salaryIncrease = offerSalaryOnlyAvg - currentSalaryOnlyAvg
        let salaryIncreaseAnnual = salaryIncrease * 12
        let percentChange = currentSalaryOnlyAvg > 0 ? (salaryIncrease / currentSalaryOnlyAvg * 100) : 0

        // Commute totals are collected on the next step (KiyaslamaCommuteView)

        ScrollView {
            VStack(spacing: 18) {
                Text("Teklif Analizi")
                    .font(AppTypography.title2)
                    .bold()
                    .foregroundColor(appTheme.textPrimary)

                // Current offer input
                // Compact current offer input: company + salary on one row
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Mevcut İş Yeri")
                                .font(AppTypography.caption1)
                                .foregroundColor(appTheme.textSecondary)
                            TextField("Şirket adı", text: $currentCompany)
                                .textFieldStyle(.roundedBorder)
                                .frame(minWidth: 120)
                        }
                        // compact money input placed inline
                        CompactMoneyField(text: $currentText, placeholder: "Maaş (₺/ay)")
                            .environmentObject(appTheme)
                            .frame(minWidth: 140)
                    }
                    .frame(maxWidth: .infinity)

                    HStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Button {
                                currentIsBrut = true
                            } label: {
                                Text("Brüt")
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(currentIsBrut ? Color(hex: "3B82F6") : appTheme.cardBackgroundSecondary)
                                    .foregroundColor(currentIsBrut ? .white : appTheme.textPrimary)
                                    .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                            Button {
                                currentIsBrut = false
                            } label: {
                                Text("Net")
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(!currentIsBrut ? Color(hex: "3B82F6") : appTheme.cardBackgroundSecondary)
                                    .foregroundColor(!currentIsBrut ? .white : appTheme.textPrimary)
                                    .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }

                        Spacer()

                        // Maas periyodu — increment (+) and decrement (-)
                        HStack(spacing: 8) {
                            Text("Yılda")
                                .font(AppTypography.caption1)
                                .foregroundColor(appTheme.textSecondary)
                            Text("\(currentMaasPeriyodu) maaş")
                                .font(AppTypography.subheadline)
                                .foregroundColor(appTheme.textPrimary)
                            HStack(spacing: 8) {
                                Button {
                                    currentMaasPeriyodu = max(1, currentMaasPeriyodu - 1)
                                } label: {
                                    Image(systemName: "minus.circle.fill").font(.title3).foregroundColor(appTheme.textPrimary.opacity(0.6))
                                }
                                .buttonStyle(.plain)
                                Button {
                                    currentMaasPeriyodu = min(24, currentMaasPeriyodu + 1)
                                } label: {
                                    Image(systemName: "plus.circle.fill").font(.title3).foregroundColor(Color(hex: "3B82F6"))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    // Yıllık prim / bonus (mevcut) - inline in same card
                    VStack(spacing: 8) {
                        KrediTextField(title: "Yıllık Prim/Bonus (₺)", text: $currentPrimText, placeholder: "0", keyboardType: .decimalPad, formatThousands: true)
                            .environmentObject(appTheme)
                        HStack(spacing: 8) {
                            Text("Prim türü:")
                                .font(AppTypography.caption1)
                                .foregroundColor(appTheme.textSecondary)
                            Button {
                                currentPrimIsBrut = true
                            } label: {
                                Text("Brüt")
                                    .font(AppTypography.caption1)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(currentPrimIsBrut ? Color(hex: "3B82F6") : appTheme.cardBackgroundSecondary)
                                    .foregroundColor(currentPrimIsBrut ? .white : appTheme.textPrimary)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                            Button {
                                currentPrimIsBrut = false
                            } label: {
                                Text("Net")
                                    .font(AppTypography.caption1)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(!currentPrimIsBrut ? Color(hex: "3B82F6") : appTheme.cardBackgroundSecondary)
                                    .foregroundColor(!currentPrimIsBrut ? .white : appTheme.textPrimary)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 14).fill(appTheme.listRowBackground))

                // Compact offer input: company + salary on one row
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Teklif Eden İş Yeri")
                                .font(AppTypography.caption1)
                                .foregroundColor(appTheme.textSecondary)
                            TextField("Şirket adı", text: $offerCompany)
                                .textFieldStyle(.roundedBorder)
                                .frame(minWidth: 120)
                        }
                        CompactMoneyField(text: $offerText, placeholder: "Maaş (₺/ay)")
                            .environmentObject(appTheme)
                            .frame(minWidth: 140)
                    }
                    .frame(maxWidth: .infinity)

                    HStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Button {
                                offerIsBrut = true
                            } label: {
                                Text("Brüt")
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(offerIsBrut ? Color(hex: "8B5CF6") : appTheme.cardBackgroundSecondary)
                                    .foregroundColor(offerIsBrut ? .white : appTheme.textPrimary)
                                    .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                            Button {
                                offerIsBrut = false
                            } label: {
                                Text("Net")
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(!offerIsBrut ? Color(hex: "8B5CF6") : appTheme.cardBackgroundSecondary)
                                    .foregroundColor(!offerIsBrut ? .white : appTheme.textPrimary)
                                    .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }

                        Spacer()
                        HStack(spacing: 8) {
                            Text("Yılda")
                                .font(AppTypography.caption1)
                                .foregroundColor(appTheme.textSecondary)
                            Text("\(offerMaasPeriyodu) maaş")
                                .font(AppTypography.subheadline)
                                .foregroundColor(appTheme.textPrimary)
                            HStack(spacing: 8) {
                                Button {
                                    offerMaasPeriyodu = max(1, offerMaasPeriyodu - 1)
                                } label: {
                                    Image(systemName: "minus.circle.fill").font(.title3).foregroundColor(appTheme.textPrimary.opacity(0.6))
                                }
                                .buttonStyle(.plain)
                                Button {
                                    offerMaasPeriyodu = min(24, offerMaasPeriyodu + 1)
                                } label: {
                                    Image(systemName: "plus.circle.fill").font(.title3).foregroundColor(Color(hex: "8B5CF6"))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    // Yıllık prim / bonus (teklif) - inline in same card
                    VStack(spacing: 8) {
                        KrediTextField(title: "Yıllık Prim/Bonus (₺)", text: $offerPrimText, placeholder: "0", keyboardType: .decimalPad, formatThousands: true)
                            .environmentObject(appTheme)
                        HStack(spacing: 8) {
                            Text("Prim türü:")
                                .font(AppTypography.caption1)
                                .foregroundColor(appTheme.textSecondary)
                            Button {
                                offerPrimIsBrut = true
                            } label: {
                                Text("Brüt")
                                    .font(AppTypography.caption1)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(offerPrimIsBrut ? Color(hex: "8B5CF6") : appTheme.cardBackgroundSecondary)
                                    .foregroundColor(offerPrimIsBrut ? .white : appTheme.textPrimary)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                            Button {
                                offerPrimIsBrut = false
                            } label: {
                                Text("Net")
                                    .font(AppTypography.caption1)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(!offerPrimIsBrut ? Color(hex: "8B5CF6") : appTheme.cardBackgroundSecondary)
                                    .foregroundColor(!offerPrimIsBrut ? .white : appTheme.textPrimary)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 14).fill(appTheme.listRowBackground))

                // Devam button — hesaplamayı yapıp yol süresi adımına gider
                NavigationLink(destination:
                                KiyaslamaCommuteView(
                                    currentSalaryOnlyMonthlyNets: currentSalaryOnlyMonthlyNets,
                                    offerSalaryOnlyMonthlyNets: offerSalaryOnlyMonthlyNets,
                                    currentWithPrimMonthlyNets: currentMonthlyNets,
                                    offerWithPrimMonthlyNets: offerMonthlyNets,
                                    currentCompany: currentCompany,
                                    offerCompany: offerCompany
                                )
                                .environmentObject(appTheme),
                               isActive: $navigateToCommute) {
                    EmptyView()
                }

                Button {
                    computeComparison()
                    withAnimation { navigateToCommute = true }
                } label: {
                    Text("Devam")
                        .font(AppTypography.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "3B82F6"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.top, 6)

                // Results are shown on the analysis screen (Devam)

                Spacer(minLength: 40)
            }
            .padding()
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .navigationTitle("Kıyaslama")
    }

    private func computeComparison() {
        // parse inputs
        let currentVal = parseFormattedNumber(currentText) ?? 0
        let offerVal = parseFormattedNumber(offerText) ?? 0
        let currentPrim = parseFormattedNumber(currentPrimText) ?? 0
        let offerPrim = parseFormattedNumber(offerPrimText) ?? 0

        // Salary-only (prim=0)
        currentSalaryOnlyMonthlyNets = computeMonthlyNet(value: currentVal, isBrut: currentIsBrut, periyod: currentMaasPeriyodu, annualPrim: 0)
        offerSalaryOnlyMonthlyNets = computeMonthlyNet(value: offerVal, isBrut: offerIsBrut, periyod: offerMaasPeriyodu, annualPrim: 0)

        // With prim handling (if prim is brut, add as jan brut; if prim is net, add as annual net)
        currentMonthlyNets = computeMonthlyNet(value: currentVal, isBrut: currentIsBrut, periyod: currentMaasPeriyodu, annualPrim: currentPrim, primIsBrut: currentPrimIsBrut)
        offerMonthlyNets = computeMonthlyNet(value: offerVal, isBrut: offerIsBrut, periyod: offerMaasPeriyodu, annualPrim: offerPrim, primIsBrut: offerPrimIsBrut)
    }

    private func computeMonthlyNet(value: Double, isBrut: Bool, periyod: Int, annualPrim: Double = 0, primIsBrut: Bool = false) -> [Double] {
        guard value > 0 else { return Array(repeating: 0, count: 12) }

        if isBrut {
            // effective monthly brut: if periyod > 12, distribute extra months into monthly equivalent
            let efektif = periyod > 12 ? (Double(periyod) * value / 12.0) : value
            let brutlar = Array(repeating: efektif, count: 12)
            let primler: [Double]
            if primIsBrut && annualPrim > 0 {
                // add entire brut prim into January (index 0)
                var p = Array(repeating: 0.0, count: 12)
                p[0] = annualPrim
                primler = p
            } else {
                primler = Array(repeating: annualPrim / 12.0, count: 12)
            }
            let sonuc = BrutNetCalculator.hesaplaYillik(brutlar: brutlar, primler: primler)
            return sonuc.map { $0.net }
        } else {
            // net provided: if prim is brut, convert brut prim to net by adding it into January brut and running calculator
            if primIsBrut && annualPrim > 0 {
                // compute net equivalent of brut prim by running calculator with first month brut = annualPrim
                let primBrutArray = [annualPrim] + Array(repeating: 0.0, count: 11)
                let primSonuc = BrutNetCalculator.hesaplaYillik(brutlar: primBrutArray)
                let primNetAnnual = primSonuc.map { $0.net }.reduce(0, +)
                let annualNet = Double(periyod) * value + primNetAnnual
                let aylik = annualNet / 12.0
                return Array(repeating: aylik, count: 12)
            } else {
                // prim is net or zero
                let annualNet = Double(periyod) * value + annualPrim
                let aylik = annualNet / 12.0
                return Array(repeating: aylik, count: 12)
            }
        }
    }
}

// Simple inline chart used in KıyaslamaView
fileprivate struct SimpleInlineChart: View {
    @EnvironmentObject var appTheme: AppTheme
    let current: [Double]
    let offer: [Double]
    let currentColor: Color
    let offerColor: Color
    private let months = ["Oca","Şub","Mar","Nis","May","Haz","Tem","Ağu","Eyl","Eki","Kas","Ara"]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let paddingX: CGFloat = 20
            let chartW = max(0, w - paddingX * 2)
            let maxVal = max((current.max() ?? 1), (offer.max() ?? 1), 1)

            ZStack {
                // offer line (new offer = purple)
                Path { path in
                    for (i, val) in offer.enumerated() {
                        let x = paddingX + (chartW) * CGFloat(i) / 11.0
                        let y = (h - 32) * (1 - CGFloat(val / maxVal)) + 8
                        if i == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }
                .stroke(offerColor, lineWidth: 1.0)

                // current line (existing job = blue)
                Path { path in
                    for (i, val) in current.enumerated() {
                        let x = paddingX + (chartW) * CGFloat(i) / 11.0
                        let y = (h - 32) * (1 - CGFloat(val / maxVal)) + 8
                        if i == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }
                .stroke(currentColor, lineWidth: 1.0)

                // month labels
                HStack(spacing: 0) {
                    ForEach(0..<12, id: \.self) { i in
                        Text(months[i])
                            .font(AppTypography.caption1.italic())
                            .foregroundColor(appTheme.textSecondary)
                            .rotationEffect(.degrees(-18))
                            .frame(width: chartW/12, alignment: .center)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 4)
            }
        }
    }
}

// Compact money input without top label — uses existing FormattedNumberField
fileprivate struct CompactMoneyField: View {
    @EnvironmentObject var appTheme: AppTheme
    @Binding var text: String
    var placeholder: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(placeholder)
                .font(AppTypography.caption1)
                .foregroundColor(appTheme.textSecondary)
            FormattedNumberField(text: $text, placeholder: placeholder, allowDecimals: false, focusTrigger: .constant(false), fontSize: 16, fontWeight: .regular, isLightMode: appTheme.isLight)
                .frame(height: 42)
                .padding(.horizontal, 8)
                .background(RoundedRectangle(cornerRadius: 10).fill(appTheme.cardBackgroundSecondary))
        }
    }
}

// Work & Commute input extracted to reduce body complexity
fileprivate struct WorkCommuteInputView: View {
    @EnvironmentObject var appTheme: AppTheme
    @Binding var currentWorkModel: WorkModel
    @Binding var currentHibritGunSayisi: Int
    @Binding var currentCommuteHours: Int
    @Binding var currentCommuteMinutes: Int

    @Binding var offerWorkModel: WorkModel
    @Binding var offerHibritGunSayisi: Int
    @Binding var offerCommuteHours: Int
    @Binding var offerCommuteMinutes: Int

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Çalışma Modeli ve Yol Süresi")
                    .font(AppTypography.subheadline)
                    .foregroundColor(appTheme.textSecondary)
                Spacer()
            }

            // Stack the two company cards vertically for small screens
            VStack(spacing: 10) {
                currentColumn
                offerColumn
            }
        }
        .padding(8)
    }

    private var currentColumn: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mevcut İş Yeri")
                .font(AppTypography.caption1)
                .foregroundColor(appTheme.textSecondary)
            HStack(spacing: 10) {
                ForEach(WorkModel.allCases, id: \.self) { m in
                    WorkModelButton(model: m,
                                    selected: currentWorkModel == m,
                                    selectedColors: [Color(hex: "3B82F6"), Color(hex: "6366F1")]) {
                        currentWorkModel = m
                    }
                    .environmentObject(appTheme)
                }
            }

            // If hybrid, show stepper below as a separate row (not inline)
            if currentWorkModel == .hybrid {
                HStack {
                    Text("Haftada ofiste gün").font(AppTypography.caption1).foregroundColor(appTheme.textSecondary)
                    Spacer()
                }
                Stepper("\(currentHibritGunSayisi) gün", value: $currentHibritGunSayisi, in: 1...5)
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Gidiş geliş süre (saat)").font(AppTypography.caption1).foregroundColor(appTheme.textSecondary)
                HStack(spacing: 8) {
                    TextField("Saat", value: $currentCommuteHours, formatter: NumberFormatter())
                        .keyboardType(.numberPad)
                        .frame(width: 64, height: 40)
                        .background(RoundedRectangle(cornerRadius: 8).fill(appTheme.cardBackgroundSecondary))
                        .multilineTextAlignment(.center)
                    Text(":")
                    TextField("Dakika", value: $currentCommuteMinutes, formatter: NumberFormatter())
                        .keyboardType(.numberPad)
                        .frame(width: 64, height: 40)
                        .background(RoundedRectangle(cornerRadius: 8).fill(appTheme.cardBackgroundSecondary))
                        .multilineTextAlignment(.center)
                }
            }

            let currentCommuteDays = currentWorkModel == .office ? 5 : (currentWorkModel == .remote ? 0 : currentHibritGunSayisi)
            let currentWeeklyHours = (Double(currentCommuteHours) + Double(currentCommuteMinutes)/60.0) * Double(currentCommuteDays)
            var currentWeeklyDisplay: String {
                if currentCommuteHours == 0 && currentCommuteMinutes == 0 { return "—" }
                return String(format: "%.1f", currentWeeklyHours)
            }
            Text("Haftalık toplam \(currentWeeklyDisplay) saat yolda")
                .font(AppTypography.caption1)
                .foregroundColor(appTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 12).fill(appTheme.listRowBackground))
    }

    private var offerColumn: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Teklif Edilen İş").font(AppTypography.caption1).foregroundColor(appTheme.textSecondary)
            HStack(spacing: 10) {
                ForEach(WorkModel.allCases, id: \.self) { m in
                    WorkModelButton(model: m,
                                    selected: offerWorkModel == m,
                                    selectedColors: [Color(hex: "8B5CF6"), Color(hex: "A78BFA")]) {
                        offerWorkModel = m
                    }
                    .environmentObject(appTheme)
                }
            }

            if offerWorkModel == .hybrid {
                HStack {
                    Text("Haftada ofiste gün").font(AppTypography.caption1).foregroundColor(appTheme.textSecondary)
                    Spacer()
                }
                Stepper("\(offerHibritGunSayisi) gün", value: $offerHibritGunSayisi, in: 1...5)
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Gidiş geliş süre (saat)").font(AppTypography.caption1).foregroundColor(appTheme.textSecondary)
                HStack(spacing: 8) {
                    TextField("Saat", value: $offerCommuteHours, formatter: NumberFormatter())
                        .keyboardType(.numberPad)
                        .frame(width: 64, height: 40)
                        .background(RoundedRectangle(cornerRadius: 8).fill(appTheme.cardBackgroundSecondary))
                        .multilineTextAlignment(.center)
                    Text(":")
                    TextField("Dakika", value: $offerCommuteMinutes, formatter: NumberFormatter())
                        .keyboardType(.numberPad)
                        .frame(width: 64, height: 40)
                        .background(RoundedRectangle(cornerRadius: 8).fill(appTheme.cardBackgroundSecondary))
                        .multilineTextAlignment(.center)
                }
            }

            let offerCommuteDays = offerWorkModel == .office ? 5 : (offerWorkModel == .remote ? 0 : offerHibritGunSayisi)
            let offerWeeklyHours = (Double(offerCommuteHours) + Double(offerCommuteMinutes)/60.0) * Double(offerCommuteDays)
            var offerWeeklyDisplay: String {
                if offerCommuteHours == 0 && offerCommuteMinutes == 0 { return "—" }
                return String(format: "%.1f", offerWeeklyHours)
            }
            Text("Haftalık toplam \(offerWeeklyDisplay) saat yolda").font(AppTypography.caption1).foregroundColor(appTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 12).fill(appTheme.listRowBackground))
    }
}

// Second-step view: collect work model & commute, then navigate to analysis
fileprivate struct KiyaslamaCommuteView: View {
    @EnvironmentObject var appTheme: AppTheme
    let currentSalaryOnlyMonthlyNets: [Double]
    let offerSalaryOnlyMonthlyNets: [Double]
    let currentWithPrimMonthlyNets: [Double]
    let offerWithPrimMonthlyNets: [Double]
    let currentCompany: String
    let offerCompany: String

    @State private var currentWorkModel: WorkModel = .office
    @State private var currentHibritGunSayisi: Int = 2
    @State private var currentCommuteHours: Int = 0
    @State private var currentCommuteMinutes: Int = 0

    @State private var offerWorkModel: WorkModel = .office
    @State private var offerHibritGunSayisi: Int = 2
    @State private var offerCommuteHours: Int = 0
    @State private var offerCommuteMinutes: Int = 0

    @State private var navigateToAnalysis: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Yol Süresi")
                    .font(AppTypography.title2)
                    .bold()
                    .foregroundColor(appTheme.textPrimary)
                    .padding(.top, 8)

                // Mevcut iş yeri kart
                VStack(alignment: .leading, spacing: 10) {
                    Text(currentCompany.isEmpty ? "Mevcut İş Yeri" : currentCompany)
                        .font(AppTypography.subheadline)
                        .foregroundColor(appTheme.textSecondary)

                    HStack(spacing: 8) {
                        ForEach(WorkModel.allCases, id: \.self) { m in
                            WorkModelButton(model: m, selected: currentWorkModel == m, selectedColors: [Color(hex: "3B82F6"), Color(hex: "6366F1")]) {
                                currentWorkModel = m
                            }
                            .environmentObject(appTheme)
                        }
                    }

                    if currentWorkModel == .hybrid {
                        HStack {
                            Text("Haftada ofiste gün").font(AppTypography.caption1).foregroundColor(appTheme.textSecondary)
                            Spacer()
                            Stepper("\(currentHibritGunSayisi) gün", value: $currentHibritGunSayisi, in: 1...5).labelsHidden()
                        }
                    }

                    HStack(spacing: 8) {
                        TextField("Saat", value: $currentCommuteHours, formatter: NumberFormatter())
                            .keyboardType(.numberPad)
                            .frame(width: 72, height: 40)
                            .background(RoundedRectangle(cornerRadius: 8).fill(appTheme.cardBackgroundSecondary))
                            .multilineTextAlignment(.center)
                        Text(":")
                        TextField("Dakika", value: $currentCommuteMinutes, formatter: NumberFormatter())
                            .keyboardType(.numberPad)
                            .frame(width: 72, height: 40)
                            .background(RoundedRectangle(cornerRadius: 8).fill(appTheme.cardBackgroundSecondary))
                            .multilineTextAlignment(.center)
                    }

                    let currentCommuteDays = currentWorkModel == .office ? 5 : (currentWorkModel == .remote ? 0 : currentHibritGunSayisi)
                    let currentWeekly = (Double(currentCommuteHours) + Double(currentCommuteMinutes)/60.0) * Double(currentCommuteDays)
                    let currentDisplay = (currentCommuteHours == 0 && currentCommuteMinutes == 0) ? "—" : String(format: "%.1f", currentWeekly)
                    Text("Haftalık toplam \(currentDisplay) saat yolda")
                        .font(AppTypography.caption1)
                        .foregroundColor(appTheme.textSecondary)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(appTheme.listRowBackground))

                // ensure tapping outside fields dismisses keyboard
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }

                // Teklif işyeri kart
                VStack(alignment: .leading, spacing: 10) {
                    Text(offerCompany.isEmpty ? "Teklif Edilen İş" : offerCompany)
                        .font(AppTypography.subheadline)
                        .foregroundColor(appTheme.textSecondary)

                    HStack(spacing: 8) {
                        ForEach(WorkModel.allCases, id: \.self) { m in
                            WorkModelButton(model: m, selected: offerWorkModel == m, selectedColors: [Color(hex: "8B5CF6"), Color(hex: "A78BFA")]) {
                                offerWorkModel = m
                            }
                            .environmentObject(appTheme)
                        }
                    }

                    if offerWorkModel == .hybrid {
                        HStack {
                            Text("Haftada ofiste gün").font(AppTypography.caption1).foregroundColor(appTheme.textSecondary)
                            Spacer()
                            Stepper("\(offerHibritGunSayisi) gün", value: $offerHibritGunSayisi, in: 1...5).labelsHidden()
                        }
                    }

                    HStack(spacing: 8) {
                        TextField("Saat", value: $offerCommuteHours, formatter: NumberFormatter())
                            .keyboardType(.numberPad)
                            .frame(width: 72, height: 40)
                            .background(RoundedRectangle(cornerRadius: 8).fill(appTheme.cardBackgroundSecondary))
                            .multilineTextAlignment(.center)
                        Text(":")
                        TextField("Dakika", value: $offerCommuteMinutes, formatter: NumberFormatter())
                            .keyboardType(.numberPad)
                            .frame(width: 72, height: 40)
                            .background(RoundedRectangle(cornerRadius: 8).fill(appTheme.cardBackgroundSecondary))
                            .multilineTextAlignment(.center)
                    }

                    let offerCommuteDays = offerWorkModel == .office ? 5 : (offerWorkModel == .remote ? 0 : offerHibritGunSayisi)
                    let offerWeekly = (Double(offerCommuteHours) + Double(offerCommuteMinutes)/60.0) * Double(offerCommuteDays)
                    let offerDisplay = (offerCommuteHours == 0 && offerCommuteMinutes == 0) ? "—" : String(format: "%.1f", offerWeekly)
                    Text("Haftalık toplam \(offerDisplay) saat yolda")
                        .font(AppTypography.caption1)
                        .foregroundColor(appTheme.textSecondary)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(appTheme.listRowBackground))

                // Navigation to analysis
                NavigationLink(destination:
                                KiyaslamaAnalysisView(
                                    currentSalaryOnlyMonthlyNets: currentSalaryOnlyMonthlyNets,
                                    offerSalaryOnlyMonthlyNets: offerSalaryOnlyMonthlyNets,
                                    currentWithPrimMonthlyNets: currentWithPrimMonthlyNets,
                                    offerWithPrimMonthlyNets: offerWithPrimMonthlyNets,
                                    currentCompany: currentCompany,
                                    offerCompany: offerCompany,
                                    currentWeeklyCommuteHours: computeWeekly(currentWorkModel, days: currentHibritGunSayisi, hours: currentCommuteHours, minutes: currentCommuteMinutes),
                                    offerWeeklyCommuteHours: computeWeekly(offerWorkModel, days: offerHibritGunSayisi, hours: offerCommuteHours, minutes: offerCommuteMinutes)
                                )
                                .environmentObject(appTheme),
                               isActive: $navigateToAnalysis) {
                    EmptyView()
                }

                Button {
                    navigateToAnalysis = true
                } label: {
                    Text("Analizi Gör")
                        .font(AppTypography.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "3B82F6"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 16)
            }
            .padding()
        }
        .navigationTitle("Yol Süresi")
    }

    private func computeWeekly(_ model: WorkModel, days: Int, hours: Int, minutes: Int) -> Double {
        let commuteDays = model == .office ? 5 : (model == .remote ? 0 : days)
        return (Double(hours) + Double(minutes)/60.0) * Double(commuteDays)
    }
}

// Analysis view shown after Devam — displays chart and monthly averages
fileprivate struct KiyaslamaAnalysisView: View {
    @EnvironmentObject var appTheme: AppTheme
    let currentSalaryOnlyMonthlyNets: [Double]
    let offerSalaryOnlyMonthlyNets: [Double]
    let currentWithPrimMonthlyNets: [Double]
    let offerWithPrimMonthlyNets: [Double]
    let currentWeeklyCommuteHours: Double
    let offerWeeklyCommuteHours: Double
    let currentCompany: String
    let offerCompany: String
    
    // Provide a custom initializer that excludes the EnvironmentObject (appTheme)
    init(currentSalaryOnlyMonthlyNets: [Double],
         offerSalaryOnlyMonthlyNets: [Double],
         currentWithPrimMonthlyNets: [Double],
         offerWithPrimMonthlyNets: [Double],
         currentCompany: String,
         offerCompany: String,
         currentWeeklyCommuteHours: Double,
         offerWeeklyCommuteHours: Double) {
        self.currentSalaryOnlyMonthlyNets = currentSalaryOnlyMonthlyNets
        self.offerSalaryOnlyMonthlyNets = offerSalaryOnlyMonthlyNets
        self.currentWithPrimMonthlyNets = currentWithPrimMonthlyNets
        self.offerWithPrimMonthlyNets = offerWithPrimMonthlyNets
        self.currentCompany = currentCompany
        self.offerCompany = offerCompany
        self.currentWeeklyCommuteHours = currentWeeklyCommuteHours
        self.offerWeeklyCommuteHours = offerWeeklyCommuteHours
    }

    private var currentSalaryOnlyAvg: Double {
        guard !currentSalaryOnlyMonthlyNets.isEmpty else { return 0 }
        return currentSalaryOnlyMonthlyNets.reduce(0, +) / Double(currentSalaryOnlyMonthlyNets.count)
    }
    private var offerSalaryOnlyAvg: Double {
        guard !offerSalaryOnlyMonthlyNets.isEmpty else { return 0 }
        return offerSalaryOnlyMonthlyNets.reduce(0, +) / Double(offerSalaryOnlyMonthlyNets.count)
    }
    private var currentWithPrimAvg: Double {
        guard !currentWithPrimMonthlyNets.isEmpty else { return 0 }
        return currentWithPrimMonthlyNets.reduce(0, +) / Double(currentWithPrimMonthlyNets.count)
    }
    private var offerWithPrimAvg: Double {
        guard !offerWithPrimMonthlyNets.isEmpty else { return 0 }
        return offerWithPrimMonthlyNets.reduce(0, +) / Double(offerWithPrimMonthlyNets.count)
    }
    
    // Prim presence helpers
    private var currentSalarySum: Double { currentSalaryOnlyMonthlyNets.reduce(0, +) }
    private var currentWithPrimSum: Double { currentWithPrimMonthlyNets.reduce(0, +) }
    private var offerSalarySum: Double { offerSalaryOnlyMonthlyNets.reduce(0, +) }
    private var offerWithPrimSum: Double { offerWithPrimMonthlyNets.reduce(0, +) }
    private var currentHasPrim: Bool { abs(currentWithPrimSum - currentSalarySum) > 1.0 }
    private var offerHasPrim: Bool { abs(offerWithPrimSum - offerSalarySum) > 1.0 }
    private var anyPrim: Bool { currentHasPrim || offerHasPrim }

    // Salary change helpers
    private var salaryIncrease: Double { offerSalaryOnlyAvg - currentSalaryOnlyAvg }
    private var salaryIncreaseAnnual: Double { salaryIncrease * 12 }
    private var percentChange: Double { currentSalaryOnlyAvg > 0 ? (salaryIncrease / currentSalaryOnlyAvg * 100) : 0 }

    private var scenarioTextComputed: String {
        if !anyPrim {
            if salaryIncrease > 0 {
                let percentStr = String(format: "%.1f", percentChange)
                return "Yeni teklif, aylık net kazancınızı \(FinanceFormatter.currencyString(salaryIncrease)) artırıyor. Bu, yıllık bazda \(FinanceFormatter.currencyString(salaryIncreaseAnnual)) ek gelir ve %\(percentStr) büyüme demek."
            } else if salaryIncrease < 0 {
                return "Yeni teklif aylık net kazancınızı \(FinanceFormatter.currencyString(abs(salaryIncrease))) azaltıyor."
            } else {
                return "Yeni teklif ve mevcut işte aylık net kazanç eşit."
            }
        } else {
            if (offerSalaryOnlyAvg > currentSalaryOnlyAvg) && (offerWithPrimAvg > currentWithPrimAvg) {
                return "Yeni teklif hem maaş hem prim açısından daha avantajlı; toplamda net kazancınız artıyor."
            } else if (offerSalaryOnlyAvg < currentSalaryOnlyAvg) && (offerWithPrimAvg > currentWithPrimAvg) {
                return "Dikkat: Yeni teklif ana maaşta düşük olsa da prim sayesinde yıllık toplamda avantajlı hale geliyor."
            } else if (currentHasPrim != offerHasPrim) {
                return "Bir iş yerinde prim var diğerinde yok; prim garantisi ile ana maaş yapısını karşılaştırın."
            } else {
                return "Prim dahil karşılaştırma analizi gösteriliyor."
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text("Teklif Analizi - Sonuç")
                    .font(AppTypography.title2)
                    .bold()
                    .foregroundColor(appTheme.textPrimary)

                // Salary-only chart
                VStack(alignment: .leading, spacing: 8) {
                    Text("Maaş (Prim hariç)")
                        .font(AppTypography.subheadline)
                        .foregroundColor(appTheme.textSecondary)
                    SimpleInlineChart(current: currentSalaryOnlyMonthlyNets, offer: offerSalaryOnlyMonthlyNets, currentColor: Color(hex: "3B82F6"), offerColor: Color(hex: "8B5CF6"))
                        .frame(height: 200)
                }
                .padding(.horizontal, 16)
                
                // Commute comparison
                VStack(alignment: .leading, spacing: 8) {
                    Text("Yol Süresi Karşılaştırması")
                        .font(AppTypography.subheadline)
                        .foregroundColor(appTheme.textSecondary)
                    HStack(spacing: 12) {
                        VStack(alignment: .leading) {
                            Text(currentCompany.isEmpty ? "Mevcut (haftalık)" : "\(currentCompany) (haftalık)")
                                .font(AppTypography.caption1)
                                .foregroundColor(appTheme.textSecondary)
                            let currentWeeklyCommuteStr = String(format: "%.1f", currentWeeklyCommuteHours)
                            Text("\(currentWeeklyCommuteStr) saat")
                                .font(AppTypography.amountMedium)
                                .foregroundColor(Color(hex: "3B82F6"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(appTheme.listRowBackground))

                        VStack(alignment: .leading) {
                            Text(offerCompany.isEmpty ? "Teklif (haftalık)" : "\(offerCompany) (haftalık)")
                                .font(AppTypography.caption1)
                                .foregroundColor(appTheme.textSecondary)
                            let offerWeeklyCommuteStr = String(format: "%.1f", offerWeeklyCommuteHours)
                            Text("\(offerWeeklyCommuteStr) saat")
                                .font(AppTypography.amountMedium)
                                .foregroundColor(Color(hex: "8B5CF6"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(appTheme.listRowBackground))
                    }
                }
                .padding(.horizontal, 16)
                HStack(spacing: 12) {
                    VStack(alignment: .leading) {
                        Text(currentCompany.isEmpty ? "Mevcut (Net / ay)" : "\(currentCompany) (Net / ay)")
                            .font(AppTypography.caption1)
                            .foregroundColor(appTheme.textSecondary)
                        Text(FinanceFormatter.currencyString(currentSalaryOnlyAvg))
                            .font(AppTypography.amountMedium)
                            .foregroundColor(Color(hex: "3B82F6"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(appTheme.listRowBackground))

                    VStack(alignment: .leading) {
                        Text(offerCompany.isEmpty ? "Teklif (Net / ay)" : "\(offerCompany) (Net / ay)")
                            .font(AppTypography.caption1)
                            .foregroundColor(appTheme.textSecondary)
                        Text(FinanceFormatter.currencyString(offerSalaryOnlyAvg))
                            .font(AppTypography.amountMedium)
                            .foregroundColor(Color(hex: "8B5CF6"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(appTheme.listRowBackground))
                }
                .padding(.horizontal, 16)
                // Prim dahil hesap (gizle eğer her iki tarafta da prim yok)
                if anyPrim {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Prim Dahil")
                            .font(AppTypography.subheadline)
                            .foregroundColor(appTheme.textSecondary)
                        SimpleInlineChart(current: currentWithPrimMonthlyNets, offer: offerWithPrimMonthlyNets, currentColor: Color(hex: "3B82F6"), offerColor: Color(hex: "8B5CF6"))
                            .frame(height: 200)
                    }
                    .padding(.horizontal, 16)

                    HStack(spacing: 12) {
                        VStack(alignment: .leading) {
                            Text(currentCompany.isEmpty ? "Mevcut (Prim dahil, Net / ay)" : "\(currentCompany) (Prim dahil, Net / ay)")
                                .font(AppTypography.caption1)
                                .foregroundColor(appTheme.textSecondary)
                            Text(FinanceFormatter.currencyString(currentWithPrimAvg))
                                .font(AppTypography.amountMedium)
                                .foregroundColor(Color(hex: "3B82F6"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(appTheme.listRowBackground))

                        VStack(alignment: .leading) {
                            Text(offerCompany.isEmpty ? "Teklif (Prim dahil, Net / ay)" : "\(offerCompany) (Prim dahil, Net / ay)")
                                .font(AppTypography.caption1)
                                .foregroundColor(appTheme.textSecondary)
                            Text(FinanceFormatter.currencyString(offerWithPrimAvg))
                                .font(AppTypography.amountMedium)
                                .foregroundColor(Color(hex: "8B5CF6"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(appTheme.listRowBackground))
                    }
                    .padding(.horizontal, 16)
                }

                // Scenario note (dynamic) — computed property used below

                VStack(alignment: .leading, spacing: 8) {
                    Text("Durum Analizi")
                        .font(AppTypography.subheadline)
                        .foregroundColor(appTheme.textSecondary)
                    Text(scenarioTextComputed)
                        .font(AppTypography.body)
                        .foregroundColor(appTheme.textPrimary)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 16)

                Spacer(minLength: 40)
            }
            .padding()
        }
        .navigationTitle("Analiz")
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
// MARK: - Dashboard (inline for project compilation)
fileprivate struct DashboardView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var appTheme: AppTheme
    @EnvironmentObject var yanHakKayitStore: YanHakKayitStore

    private var bakiye: Double { dataManager.balance }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Toplam Finansal Sağlık")
                            .font(AppTypography.subheadline)
                            .foregroundColor(appTheme.textSecondary)
                        Text(FinanceFormatter.currencyString(bakiye))
                            .font(AppTypography.amountLarge)
                            .foregroundColor(appTheme.textPrimary)
                    }
                    Spacer()
                    ProgressView(value: min(max(bakiye / 100_000, 0), 1.0))
                        .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: "34D399")))
                        .frame(width: 120)
                }
                .padding()
                .background(appTheme.cardBackground)
                .cornerRadius(14)
                .shadow(color: Color.black.opacity(0.03), radius: 8, y: 4)
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Kariyer Stratejisi", subtitle: "Tekliflerini ve gelişimini yönet")
                    NavigationLink(destination: YanHakAnaliziView().environmentObject(yanHakKayitStore)) {
                        FeaturedCard(title: "İş Teklifi Analizi", description: "Yeni teklifleri yaşam kalitesi ve kariyer etkisiyle kıyasla.", icon: "briefcase.fill", color: Color(hex: "3B82F6"))
                    }
                    // Yeni buton: Kıyaslama (aynı boyut ve yapı)
                    NavigationLink(destination: KiyaslamaView()) {
                        FeaturedCard(title: "Kıyaslama", description: "Geliştirmeleri buraya ekleyeceğiz.", icon: "arrow.left.and.right", color: Color(hex: "8B5CF6"))
                    }
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Finansal Durum", subtitle: "Nakit akışını ve yatırımlarını izle")
                    HStack(spacing: 16) {
                        NavigationLink(destination: BudgetView()) {
                            SquareModuleCard(title: "Bütçe", icon: "banknote.fill", color: Color(hex: "10B981"))
                        }
                        NavigationLink(destination: PortfolioView()) {
                            SquareModuleCard(title: "Portföy", icon: "chart.pie.fill", color: Color(hex: "8B5CF6"))
                        }
                    }
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Yardımcı Araçlar", subtitle: "Hesaplamalar ve simülasyonlar")
                    NavigationLink(destination: KrediHesaplamaView()) {
                        ToolRow(title: "Kredi Hesaplama", icon: "percent", color: Color(hex: "F59E0B"))
                    }
                    NavigationLink(destination: BrutNetView()) {
                        ToolRow(title: "Maaş Hesaplama", icon: "dollarsign.circle", color: Color(hex: "34D399"))
                    }
                }
                .padding(.horizontal)

                Spacer(minLength: 40)
            }
            .padding(.vertical)
        }
    }
}

fileprivate struct SectionHeader: View {
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(AppTypography.title2).bold().foregroundColor(.primary)
            Text(subtitle).font(AppTypography.footnote).foregroundColor(.secondary)
        }
    }
}

fileprivate struct FeaturedCard: View {
    let title: String; let description: String; let icon: String; let color: Color
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon).font(.title).foregroundColor(color)
                Text(title).font(AppTypography.headline).foregroundColor(.primary)
                Text(description).font(AppTypography.callout).foregroundColor(.secondary).multilineTextAlignment(.leading)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.footnote).foregroundColor(.secondary)
        }
        .padding(20)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
    }
}

fileprivate struct SquareModuleCard: View {
    let title: String; let icon: String; let color: Color
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon).font(.title2).foregroundColor(color)
            Text(title).font(AppTypography.callout).fontWeight(.semibold).foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
    }
}

fileprivate struct ToolRow: View {
    let title: String; let icon: String; let color: Color
    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(color).frame(width: 32)
            Text(title).font(AppTypography.subheadline).fontWeight(.medium)
            Spacer()
            Image(systemName: "arrow.up.right").font(.caption2).foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

#Preview {
    ContentView()
        .environmentObject(DataManager.shared)
        .environmentObject(AppTheme())
}
