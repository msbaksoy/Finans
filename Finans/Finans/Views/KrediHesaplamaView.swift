import SwiftUI

enum KrediTuru: String, CaseIterable {
    case tuketici = "Tüketici Kredisi"
    case konut = "Konut Kredisi"
    case tasit = "Taşıt Kredisi"
}

struct KrediHesaplamaView: View {
    var body: some View {
        ZStack {
            Color(hex: "0F172A").ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    Text("Kredi Türü Seçin")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                    
                    ForEach(KrediTuru.allCases, id: \.self) { tur in
                        NavigationLink(destination: krediDetayView(tur)) {
                            HStack(spacing: 20) {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(krediTuruRengi(tur).opacity(0.2))
                                    .frame(width: 56, height: 56)
                                    .overlay(
                                        Image(systemName: krediTuruIkon(tur))
                                            .font(.system(size: 24))
                                            .foregroundColor(krediTuruRengi(tur))
                                    )
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(tur.rawValue)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                    Text(krediTuruAltYazi(tur))
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
                                            .stroke(krediTuruRengi(tur).opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding(24)
            }
        }
        .navigationTitle("Kredi Hesaplama")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color(hex: "0F172A"), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
    
    @ViewBuilder
    private func krediDetayView(_ tur: KrediTuru) -> some View {
        switch tur {
        case .tuketici:
            TuketiciKredisiView()
        case .konut:
            KonutKredisiView()
        case .tasit:
            TasitKredisiView()
        }
    }
    
    private func krediTuruRengi(_ tur: KrediTuru) -> Color {
        switch tur {
        case .tuketici: return Color(hex: "8B5CF6")
        case .konut: return Color(hex: "06B6D4")
        case .tasit: return Color(hex: "F59E0B")
        }
    }
    
    private func krediTuruIkon(_ tur: KrediTuru) -> String {
        switch tur {
        case .tuketici: return "creditcard.fill"
        case .konut: return "house.fill"
        case .tasit: return "car.fill"
        }
    }
    
    private func krediTuruAltYazi(_ tur: KrediTuru) -> String {
        switch tur {
        case .tuketici: return "İhtiyaç kredisi, KKDF ve BSMV dahil"
        case .konut: return "KKDF/BSMV yok, sadece faiz"
        case .tasit: return "Taşıt kredisi hesaplama"
        }
    }
}

// MARK: - Placeholder (Konut/Taşıt henüz hazır değil)
struct PlaceholderKrediView: View {
    let tur: String
    let mesaj: String
    
    var body: some View {
        ZStack {
            Color(hex: "0F172A").ignoresSafeArea()
            VStack(spacing: 24) {
                Image(systemName: "hammer.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.white.opacity(0.4))
                Text(tur)
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
                Text(mesaj)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(40)
        }
        .navigationTitle(tur)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color(hex: "0F172A"), for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        KrediHesaplamaView()
    }
}
