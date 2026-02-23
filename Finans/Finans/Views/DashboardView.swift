import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var appTheme: AppTheme
    @EnvironmentObject var yanHakKayitStore: YanHakKayitStore

    private var bakiye: Double { dataManager.balance }
    private var teklifSayisi: Int { yanHakKayitStore.all.count }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Health / quick summary
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
                    ProgressView(value: min(max(bakiye / 100_000, 0), 1.0)) // basit normalize
                        .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: "34D399")))
                        .frame(width: 120)
                }
                .padding()
                .background(appTheme.cardBackground)
                .cornerRadius(14)
                .shadow(color: Color.black.opacity(0.03), radius: 8, y: 4)
                .padding(.horizontal)

                // 1. SEKTÖR: KARİYER VE GELİR (LOKOMOTİF)
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Kariyer Stratejisi", subtitle: "Tekliflerini ve gelişimini yönet")

                    NavigationLink(destination: YanHakAnaliziView().environmentObject(yanHakKayitStore)) {
                        FeaturedCard(
                            title: "İş Teklifi Analizi",
                            description: "Yeni teklifleri yaşam kalitesi ve kariyer etkisiyle kıyasla.",
                            icon: "briefcase.fill",
                            color: Color(hex: "3B82F6")
                        )
                    }
                    // (Only the original İş Teklifi Analizi card is shown)
                }
                .padding(.horizontal)

                // 2. SEKTÖR: VARLIK YÖNETİMİ
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

                // 3. SEKTÖR: ARAÇLAR
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

// MARK: - ALT BİLEŞENLER
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

