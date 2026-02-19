import SwiftUI
import Charts

struct PortfolioView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showAddAsset = false
    @State private var assetToEdit: Asset?
    
    var body: some View {
        ZStack {
            Color(hex: "0F172A").ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Toplam portföy değeri
                    PortfolioTotalCard(amount: dataManager.totalPortfolioValue)
                        .padding(.horizontal, 20)
                    
                    // Pasta grafiği
                    if !dataManager.assets.isEmpty {
                        PortfolioChartView(assets: dataManager.assets)
                            .frame(height: 220)
                            .padding(.horizontal, 20)
                    }
                    
                    // Varlık ekle butonu
                    Button {
                        showAddAsset = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                            Text("Varlık Ekle")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(hex: "60A5FA"))
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.horizontal, 20)
                    
                    // Varlık listesi
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Varlıklarım")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                        
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
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 24)
            }
        }
        .navigationTitle("Portföy")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color(hex: "0F172A"), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $showAddAsset) {
            AddAssetView()
        }
        .sheet(item: $assetToEdit) { asset in
            EditAssetView(asset: asset)
        }
    }
}

struct PortfolioTotalCard: View {
    let amount: Double
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Toplam Portföy Değeri")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            Text(formatCurrency(amount))
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(Color(hex: "60A5FA"))
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "1E3A5F"),
                            Color(hex: "0F172A")
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
                                    Color(hex: "60A5FA").opacity(0.5),
                                    Color(hex: "3B82F6").opacity(0.2)
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
                .foregroundColor(.white)
            
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
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(1)
                            Spacer()
                            Text(formatCurrency(item.value))
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

struct EmptyChartView: View {
    var body: some View {
        Text("Veri yok")
            .font(.subheadline)
            .foregroundColor(.white.opacity(0.5))
            .frame(maxWidth: .infinity)
            .frame(height: 120)
    }
}

struct AssetRowView: View {
    let asset: Asset
    
    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 12)
                .fill(assetColor.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: assetIcon)
                        .font(.system(size: 20))
                        .foregroundColor(assetColor)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(asset.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Text(asset.displayType)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                if asset.type.supportsQuantityAndPrice, let q = asset.quantity, let p = asset.pricePerUnit {
                    Text("\(formatNumber(q)) adet × \(formatCurrency(p))")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatCurrency(asset.totalValue))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "60A5FA"))
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
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
    }
}
