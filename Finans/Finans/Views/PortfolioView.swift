import SwiftUI
import Charts

struct PortfolioView: View {
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var appTheme: AppTheme
    @State private var showAddAsset = false
    @State private var assetToEdit: Asset?
    
    var body: some View {
        ZStack {
            appTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppSpacing.xxl) {
                    // Toplam portföy değeri
                    PortfolioTotalCard(amount: dataManager.totalPortfolioValue)
                        .padding(.horizontal, AppSpacing.xxl)
                    
                    // Pasta grafiği
                    if !dataManager.assets.isEmpty {
                        PortfolioChartView(assets: dataManager.assets)
                            .frame(height: 220)
                            .padding(.horizontal, AppSpacing.xxl)
                    }
                    
                    // Varlık ekle butonu
                    Button {
                        showAddAsset = true
                    } label: {
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: "plus.circle.fill")
                                .font(AppTypography.headline)
                            Text("Varlık Ekle")
                                .font(AppTypography.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(hex: "60A5FA"))
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.horizontal, AppSpacing.xxl)
                    
                    // Varlık listesi
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("Varlıklarım")
                            .font(AppTypography.headline)
                            .foregroundColor(appTheme.textPrimary)
                            .padding(.horizontal, AppSpacing.xs)
                        
                        if dataManager.assets.isEmpty {
                            EmptyStateView(
                                icon: "chart.pie",
                                message: "Henüz varlık eklenmedi",
                                submessage: "Yukarıdaki butondan varlıklarınızı ekleyebilirsiniz"
                            )
                            .padding(.vertical, 40)
                        } else {
                            ForEach(dataManager.assets.sorted { $0.totalValue > $1.totalValue }) { asset in
                                AssetRowView(asset: asset)
                                    .onTapGesture {
                                        assetToEdit = asset
                                    }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            dataManager.deleteAsset(asset)
                                        } label: {
                                            Label("Sil", systemImage: "trash")
                                        }
                                        Button {
                                            assetToEdit = asset
                                        } label: {
                                            Label("Düzenle", systemImage: "pencil")
                                        }
                                    }
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.xxl)
                }
                .padding(.vertical, AppSpacing.xxl)
            }
        }
        .navigationTitle("Portföy")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(appTheme.isLight ? .light : .dark, for: .navigationBar)
        .toolbarBackground(appTheme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $showAddAsset) {
            AddAssetView().environmentObject(appTheme)
        }
        .sheet(item: $assetToEdit) { asset in
            EditAssetView(asset: asset).environmentObject(appTheme)
        }
    }
}

struct PortfolioTotalCard: View {
    let amount: Double
    @EnvironmentObject var appTheme: AppTheme
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Toplam Portföy Değeri")
                .font(.subheadline)
                .foregroundColor(appTheme.textSecondary)
            Text(formatCurrency(amount))
                .font(AppTypography.amountLarge)
                .monospacedDigit()
                .foregroundColor(Color(hex: "60A5FA"))
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.xxl)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    appTheme.isLight
                        ? LinearGradient(colors: [Color(hex: "E0F2FE"), Color(hex: "F0F9FF")], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [Color(hex: "1E3A5F"), Color(hex: "0F172A")], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(hex: "60A5FA").opacity(0.4),
                                    Color(hex: "3B82F6").opacity(0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                )
        )
    }
}

private let chartColorPalette: [Color] = [
    Color(hex: "60A5FA"),
    Color(hex: "34D399"),
    Color(hex: "F59E0B"),
    Color(hex: "A78BFA"),
    Color(hex: "F87171"),
    Color(hex: "22D3EE")
]

struct ChartDataItem: Identifiable {
    let id = UUID()
    let type: String
    let value: Double
    let color: Color
}

struct PortfolioChartView: View {
    let assets: [Asset]
    @EnvironmentObject var appTheme: AppTheme
    
    private var chartData: [ChartDataItem] {
        let grouped = Dictionary(grouping: assets, by: { $0.displayType })
            .mapValues { $0.reduce(0) { $0 + $1.totalValue } }
            .map { (type: $0.key, value: $0.value) }
            .sorted { $0.value > $1.value }
        return grouped.enumerated().map { index, item in
            ChartDataItem(type: item.type, value: item.value, color: chartColorPalette[index % chartColorPalette.count])
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Varlık Dağılımı")
                .font(.headline)
                .foregroundColor(appTheme.textPrimary)
            
            if chartData.isEmpty {
                EmptyChartView()
            } else {
                Chart(chartData) { item in
                    SectorMark(
                        angle: .value("Değer", item.value),
                        innerRadius: .ratio(0.55),
                        angularInset: 2
                    )
                    .foregroundStyle(item.color)
                    .cornerRadius(4)
                }
                .chartLegend(.hidden)
                
                // Legend
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(chartData) { item in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(item.color)
                                .frame(width: 8, height: 8)
                            Text(item.type)
                                .font(.caption)
                                .foregroundColor(appTheme.textPrimary)
                                .lineLimit(1)
                            Spacer()
                            Text(formatCurrency(item.value))
                                .font(AppTypography.amountSmall)
                                .monospacedDigit()
                                .foregroundColor(appTheme.textSecondary)
                        }
                    }
                }
            }
        }
        .padding(AppSpacing.xl)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(appTheme.listRowBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(appTheme.cardStroke.opacity(0.6), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(appTheme.isLight ? 0.03 : 0), radius: appTheme.isLight ? 8 : 0, y: 4)
        )
    }
}

struct EmptyChartView: View {
    @EnvironmentObject var appTheme: AppTheme
    var body: some View {
        Text("Veri yok")
            .font(.subheadline)
            .foregroundColor(appTheme.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 120)
    }
}

struct AssetRowView: View {
    let asset: Asset
    @EnvironmentObject var appTheme: AppTheme
    
    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 12)
                .fill(assetColor.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: assetIcon)
                        .font(AppTypography.headline)
                        .foregroundColor(assetColor)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(asset.name)
                    .font(AppTypography.headline)
                    .foregroundColor(appTheme.textPrimary)
                Text(asset.displayType)
                    .font(.caption)
                    .foregroundColor(appTheme.textSecondary)
                if asset.type.supportsQuantityAndPrice, let q = asset.quantity, let p = asset.pricePerUnit {
                    Text("\(formatNumber(q)) adet × \(formatCurrency(p))")
                        .font(.caption2)
                        .monospacedDigit()
                        .foregroundColor(appTheme.textSecondary.opacity(0.9))
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatCurrency(asset.totalValue))
                    .font(AppTypography.amountSmall)
                    .monospacedDigit()
                    .foregroundColor(Color(hex: "60A5FA"))
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(appTheme.textSecondary.opacity(0.8))
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(appTheme.cardBackgroundSecondary)
                .shadow(color: .black.opacity(appTheme.isLight ? 0.03 : 0), radius: appTheme.isLight ? 8 : 0, y: 4)
        )
    }
    
    private var assetColor: Color {
        switch asset.type {
        case .stock, .etf: return Color(hex: "60A5FA")
        case .bond: return Color(hex: "34D399")
        case .bankDeposit: return Color(hex: "22D3EE")
        case .crypto: return Color(hex: "F59E0B")
        case .gold: return Color(hex: "FBBF24")
        case .realEstate: return Color(hex: "A78BFA")
        default: return Color(hex: "94A3B8")
        }
    }
    
    private var assetIcon: String {
        switch asset.type {
        case .stock, .etf: return "chart.line.uptrend.xyaxis"
        case .bond: return "doc.text"
        case .bankDeposit: return "building.columns"
        case .crypto: return "bitcoinsign.circle"
        case .gold: return "dollarsign"
        case .realEstate: return "house"
        default: return "square.stack.3d.up"
        }
    }
}

func formatNumber(_ n: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 2
    return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
}

#Preview {
    NavigationStack {
        PortfolioView()
            .environmentObject(DataManager.shared)
            .environmentObject(AppTheme())
    }
}
