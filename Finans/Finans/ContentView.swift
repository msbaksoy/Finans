import SwiftUI

private enum NavTarget: Hashable {
    case budget, portfolio, brutNet, kredi
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
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Hero bölümü
                        heroSection
                            .padding(.top, AppSpacing.xxl)
                            .padding(.bottom, AppSpacing.xxl * 2)
                        
                        // Özellik kartları
                        VStack(spacing: AppSpacing.lg) {
                            PremiumMenuCard(
                                icon: "banknote.fill",
                                title: "Bütçe",
                                subtitle: "Gelir ve gider takibi",
                                accentColor: Color(hex: "10B981"),
                                accentSecondary: Color(hex: "34D399")
                            ) { navPath.append(NavTarget.budget) }
                            
                            PremiumMenuCard(
                                icon: "chart.line.uptrend.xyaxis",
                                title: "Portföy",
                                subtitle: "Varlık dağılımı",
                                accentColor: Color(hex: "3B82F6"),
                                accentSecondary: Color(hex: "60A5FA")
                            ) { navPath.append(NavTarget.portfolio) }
                            
                            PremiumMenuCard(
                                icon: "person.2.fill",
                                title: "İnsan Kaynakları",
                                subtitle: "Maaş hesaplama",
                                accentColor: Color(hex: "D97706"),
                                accentSecondary: Color(hex: "F59E0B")
                            ) { navPath.append(NavTarget.brutNet) }
                            
                            PremiumMenuCard(
                                icon: "creditcard.fill",
                                title: "Kredi Hesaplama",
                                subtitle: "Kredi ve mevduat",
                                accentColor: Color(hex: "7C3AED"),
                                accentSecondary: Color(hex: "8B5CF6")
                            ) { navPath.append(NavTarget.kredi) }
                        }
                        .padding(.horizontal, AppSpacing.xxl)
                        .padding(.bottom, AppSpacing.xxl * 2)
                    }
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
        VStack(spacing: 16) {
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
                    .frame(width: 88, height: 88)
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
                .font(AppTypography.largeTitle)
                .foregroundColor(appTheme.textPrimary)
            
            Text("Finansal yolculuğunuza hoş geldiniz")
                .font(AppTypography.callout)
                .foregroundColor(appTheme.textSecondary)
        }
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
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
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

#Preview {
    ContentView()
        .environmentObject(DataManager.shared)
        .environmentObject(AppTheme())
}
