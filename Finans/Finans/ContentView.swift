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
    var body: some View {
        VStack(spacing: 16) {
            Text("Kıyaslama")
                .font(AppTypography.title2)
                .bold()
            Text("Bu alan geliştirmeleriniz için ayrıldı. Buraya özellikleri ekleyebiliriz.")
                .font(AppTypography.callout)
                .foregroundColor(.secondary)
        }
        .padding()
        .navigationTitle("Kıyaslama")
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
