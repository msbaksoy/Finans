import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Arka plan gradient
                LinearGradient(
                    colors: [
                        Color(hex: "0F172A"),
                        Color(hex: "1E293B")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    // Başlık
                    VStack(spacing: 8) {
                        Image(systemName: "chart.pie.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "34D399"), Color(hex: "10B981")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Finans")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Finansal yolculuğunuza hoş geldiniz")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.bottom, 48)
                    
                    // Butonlar
                    VStack(spacing: 20) {
                        NavigationLink(destination: BudgetView()) {
                            MenuButton(
                                icon: "banknote.fill",
                                title: "Bütçe",
                                subtitle: "Gelir ve giderlerinizi yönetin",
                                accentColor: Color(hex: "34D399")
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        NavigationLink(destination: PortfolioView()) {
                            MenuButton(
                                icon: "chart.line.uptrend.xyaxis",
                                title: "Portföy",
                                subtitle: "Yatırımlarınızı takip edin",
                                accentColor: Color(hex: "60A5FA")
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        NavigationLink(destination: BrutNetView()) {
                            MenuButton(
                                icon: "percent",
                                title: "Brütten Nete",
                                subtitle: "Brüt maaştan net maaş hesaplama",
                                accentColor: Color(hex: "F59E0B")
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        NavigationLink(destination: KrediHesaplamaView()) {
                            MenuButton(
                                icon: "creditcard.fill",
                                title: "Kredi Hesaplama",
                                subtitle: "Tüketici, konut ve taşıt kredisi",
                                accentColor: Color(hex: "8B5CF6")
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            dataManager.brutNetVerileriniTemizle()
        }
    }
}

struct MenuButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let accentColor: Color
    
    var body: some View {
        HStack(spacing: 20) {
            RoundedRectangle(cornerRadius: 16)
                .fill(accentColor.opacity(0.2))
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(accentColor)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
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
}
