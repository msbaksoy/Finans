import SwiftUI

// Kıyaslama akışı: maaş, yol, yemek, pozisyon ve analiz ekranları

struct KiyaslamaView: View {
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
        // (detailed averages and scenario analysis computed in the Analysis view)

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

                Spacer(minLength: 40)
            }
            .padding()
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .navigationDestination(isPresented: $navigateToCommute) {
            KiyaslamaCommuteView(
                currentSalaryOnlyMonthlyNets: currentSalaryOnlyMonthlyNets,
                offerSalaryOnlyMonthlyNets: offerSalaryOnlyMonthlyNets,
                currentWithPrimMonthlyNets: currentMonthlyNets,
                offerWithPrimMonthlyNets: offerMonthlyNets,
                currentCompany: currentCompany,
                offerCompany: offerCompany
            )
            .environmentObject(appTheme)
        }
        .navigationTitle("Kıyaslama")
    }

    private func computeComparison() {
        let currentVal = parseFormattedNumber(currentText) ?? 0
        let offerVal = parseFormattedNumber(offerText) ?? 0
        let currentPrim = parseFormattedNumber(currentPrimText) ?? 0
        let offerPrim = parseFormattedNumber(offerPrimText) ?? 0

        currentSalaryOnlyMonthlyNets = computeMonthlyNet(value: currentVal, isBrut: currentIsBrut, periyod: currentMaasPeriyodu, annualPrim: 0)
        offerSalaryOnlyMonthlyNets = computeMonthlyNet(value: offerVal, isBrut: offerIsBrut, periyod: offerMaasPeriyodu, annualPrim: 0)

        currentMonthlyNets = computeMonthlyNet(value: currentVal, isBrut: currentIsBrut, periyod: currentMaasPeriyodu, annualPrim: currentPrim, primIsBrut: currentPrimIsBrut)
        offerMonthlyNets = computeMonthlyNet(value: offerVal, isBrut: offerIsBrut, periyod: offerMaasPeriyodu, annualPrim: offerPrim, primIsBrut: offerPrimIsBrut)
    }

    private func computeMonthlyNet(value: Double, isBrut: Bool, periyod: Int, annualPrim: Double = 0, primIsBrut: Bool = false) -> [Double] {
        guard value > 0 else { return Array(repeating: 0, count: 12) }

        if isBrut {
            let efektif = periyod > 12 ? (Double(periyod) * value / 12.0) : value
            let brutlar = Array(repeating: efektif, count: 12)
            let primler: [Double]
            if primIsBrut && annualPrim > 0 {
                var p = Array(repeating: 0.0, count: 12)
                p[0] = annualPrim
                primler = p
            } else {
                primler = Array(repeating: annualPrim / 12.0, count: 12)
            }
            let sonuc = BrutNetCalculator.hesaplaYillik(brutlar: brutlar, primler: primler)
            return sonuc.map { $0.net }
        } else {
            if primIsBrut && annualPrim > 0 {
                let primBrutArray = [annualPrim] + Array(repeating: 0.0, count: 11)
                let primSonuc = BrutNetCalculator.hesaplaYillik(brutlar: primBrutArray)
                let primNetAnnual = primSonuc.map { $0.net }.reduce(0, +)
                let annualNet = Double(periyod) * value + primNetAnnual
                let aylik = annualNet / 12.0
                return Array(repeating: aylik, count: 12)
            } else {
                let annualNet = Double(periyod) * value + annualPrim
                let aylik = annualNet / 12.0
                return Array(repeating: aylik, count: 12)
            }
        }
    }
}

// Second-step view: collect work model & commute, then navigate to analysis
struct KiyaslamaCommuteView: View {
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

    @State private var navigateToYemek: Bool = false

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
                            Stepper(value: $currentHibritGunSayisi, in: 1...5) {
                                Text("\(currentHibritGunSayisi) gün")
                                    .font(AppTypography.caption1)
                                    .foregroundColor(appTheme.textSecondary)
                            }
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
                            Stepper(value: $offerHibritGunSayisi, in: 1...5) {
                                Text("\(offerHibritGunSayisi) gün")
                                    .font(AppTypography.caption1)
                                    .foregroundColor(appTheme.textSecondary)
                            }
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

                Button {
                    navigateToYemek = true
                } label: {
                    Text("Devam")
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
        .navigationDestination(isPresented: $navigateToYemek) {
            KiyaslamaYemekView(
                currentSalaryOnlyMonthlyNets: currentSalaryOnlyMonthlyNets,
                offerSalaryOnlyMonthlyNets: offerSalaryOnlyMonthlyNets,
                currentWithPrimMonthlyNets: currentWithPrimMonthlyNets,
                offerWithPrimMonthlyNets: offerWithPrimMonthlyNets,
                currentCompany: currentCompany,
                offerCompany: offerCompany,
                currentWeeklyCommuteHours: computeWeekly(currentWorkModel, days: currentHibritGunSayisi, hours: currentCommuteHours, minutes: currentCommuteMinutes),
                offerWeeklyCommuteHours: computeWeekly(offerWorkModel, days: offerHibritGunSayisi, hours: offerCommuteHours, minutes: offerCommuteMinutes)
            )
            .environmentObject(appTheme)
        }
        .navigationTitle("Yol Süresi")
    }

    private func computeWeekly(_ model: WorkModel, days: Int, hours: Int, minutes: Int) -> Double {
        let commuteDays = model == .office ? 5 : (model == .remote ? 0 : days)
        return (Double(hours) + Double(minutes)/60.0) * Double(commuteDays)
    }
}

// Yemek imkanı sorusu: Yemekhane / Yemek Kartı / Yok (yol süresinden sonra, terfiden önce)
struct KiyaslamaYemekView: View {
    @EnvironmentObject var appTheme: AppTheme
    let currentSalaryOnlyMonthlyNets: [Double]
    let offerSalaryOnlyMonthlyNets: [Double]
    let currentWithPrimMonthlyNets: [Double]
    let offerWithPrimMonthlyNets: [Double]
    let currentCompany: String
    let offerCompany: String
    let currentWeeklyCommuteHours: Double
    let offerWeeklyCommuteHours: Double

    @State private var currentYemek: YemekImkani? = nil
    @State private var currentKalite: Int = 0
    @State private var currentGunlukTutarText: String = ""
    @State private var offerYemek: YemekImkani? = nil
    @State private var offerKalite: Int = 0
    @State private var offerGunlukTutarText: String = ""
    @State private var navigateToSoru3: Bool = false

    private var canDevam: Bool {
        currentYemek != nil && offerYemek != nil
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Yemek imkanı")
                    .font(AppTypography.title2)
                    .bold()
                    .foregroundColor(appTheme.textPrimary)
                    .padding(.top, 8)

                Text("Mevcut iş ve teklifte yemek imkanı nasıl?")
                    .font(AppTypography.subheadline)
                    .foregroundColor(appTheme.textSecondary)
                    .multilineTextAlignment(.center)

                yemekKartiBlock(
                    title: currentCompany.isEmpty ? "Mevcut İş Yeri" : currentCompany,
                    selection: $currentYemek,
                    kalite: $currentKalite,
                    gunlukTutarText: $currentGunlukTutarText,
                    accentColor: Color(hex: "3B82F6")
                )

                yemekKartiBlock(
                    title: offerCompany.isEmpty ? "Teklif Edilen İş" : offerCompany,
                    selection: $offerYemek,
                    kalite: $offerKalite,
                    gunlukTutarText: $offerGunlukTutarText,
                    accentColor: Color(hex: "8B5CF6")
                )

                Button {
                    navigateToSoru3 = true
                } label: {
                    Text("Devam")
                        .font(AppTypography.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canDevam ? Color(hex: "3B82F6") : appTheme.textSecondary.opacity(0.5))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(!canDevam)
                .padding(.horizontal, 16)
                .padding(.top, 8)

                Spacer(minLength: 40)
            }
            .padding()
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .navigationDestination(isPresented: $navigateToSoru3) {
            KiyaslamaSoru3View(
                currentSalaryOnlyMonthlyNets: currentSalaryOnlyMonthlyNets,
                offerSalaryOnlyMonthlyNets: offerSalaryOnlyMonthlyNets,
                currentWithPrimMonthlyNets: currentWithPrimMonthlyNets,
                offerWithPrimMonthlyNets: offerWithPrimMonthlyNets,
                currentCompany: currentCompany,
                offerCompany: offerCompany,
                currentWeeklyCommuteHours: currentWeeklyCommuteHours,
                offerWeeklyCommuteHours: offerWeeklyCommuteHours
            )
            .environmentObject(appTheme)
        }
        .navigationTitle("Yemek İmkanı")
    }

    @ViewBuilder
    private func yemekKartiBlock(
        title: String,
        selection: Binding<YemekImkani?>,
        kalite: Binding<Int>,
        gunlukTutarText: Binding<String>,
        accentColor: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(AppTypography.subheadline)
                .foregroundColor(appTheme.textSecondary)

            HStack(spacing: 10) {
                ForEach(YemekImkani.allCases, id: \.self) { opt in
                    Button {
                        selection.wrappedValue = opt
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: opt.icon)
                                .font(.title2)
                            Text(opt.rawValue)
                                .font(AppTypography.caption1)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selection.wrappedValue == opt ? accentColor : appTheme.listRowBackground)
                        .foregroundColor(selection.wrappedValue == opt ? .white : appTheme.textPrimary)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }

            if selection.wrappedValue == .yemekhane {
                HStack(spacing: 8) {
                    Text("Yemeklerin kalitesi (1–5)")
                        .font(AppTypography.caption1)
                        .foregroundColor(appTheme.textSecondary)
                    Spacer()
                    HStack(spacing: 4) {
                        ForEach(1...5, id: \.self) { star in
                            Button {
                                kalite.wrappedValue = star
                            } label: {
                                Image(systemName: star <= kalite.wrappedValue ? "star.fill" : "star")
                                    .font(.title3)
                                    .foregroundColor(star <= kalite.wrappedValue ? Color(hex: "F59E0B") : appTheme.textSecondary.opacity(0.5))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.top, 4)
            }

            if selection.wrappedValue == .yemekKarti {
                HStack(spacing: 8) {
                    Image(systemName: "creditcard.fill")
                        .foregroundColor(accentColor)
                    Text("Günlük yemek tutarı (₺)")
                        .font(AppTypography.caption1)
                        .foregroundColor(appTheme.textSecondary)
                    TextField("0", text: gunlukTutarText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(appTheme.cardBackgroundSecondary))
                        .foregroundColor(appTheme.textPrimary)
                }
                .padding(.top, 4)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(appTheme.listRowBackground))
        .padding(.horizontal, 16)
    }
}

// Third question: position type (terfi / aynı ünvan), then navigate to analysis
struct KiyaslamaSoru3View: View {
    @EnvironmentObject var appTheme: AppTheme
    let currentSalaryOnlyMonthlyNets: [Double]
    let offerSalaryOnlyMonthlyNets: [Double]
    let currentWithPrimMonthlyNets: [Double]
    let offerWithPrimMonthlyNets: [Double]
    let currentCompany: String
    let offerCompany: String
    let currentWeeklyCommuteHours: Double
    let offerWeeklyCommuteHours: Double

    @State private var terfiIleMi: Bool? = nil
    @State private var mevcutUnvan: UnvanItem? = nil
    @State private var teklifUnvan: UnvanItem? = nil
    @State private var navigateToAnalysis: Bool = false

    private var canShowAnalysis: Bool {
        guard let terfi = terfiIleMi else { return false }
        if !terfi { return true }
        return mevcutUnvan != nil && teklifUnvan != nil
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Teklifteki pozisyon nasıl?")
                    .font(AppTypography.title2)
                    .bold()
                    .foregroundColor(appTheme.textPrimary)
                    .padding(.top, 8)
                    .multilineTextAlignment(.center)

                Text("Terfi alarak mı yoksa aynı ünvanda mı geçiş yapıyorsunuz?")
                    .font(AppTypography.subheadline)
                    .foregroundColor(appTheme.textSecondary)
                    .multilineTextAlignment(.center)

                VStack(spacing: 12) {
                    Button {
                        terfiIleMi = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.up.forward")
                                .font(.title2)
                            Text("Terfi alarak")
                                .font(AppTypography.headline)
                            Spacer()
                            if terfiIleMi == true {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.white)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(terfiIleMi == true ? Color(hex: "8B5CF6") : appTheme.listRowBackground)
                        .foregroundColor(terfiIleMi == true ? .white : appTheme.textPrimary)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)

                    Button {
                        terfiIleMi = false
                        mevcutUnvan = nil
                        teklifUnvan = nil
                    } label: {
                        HStack {
                            Image(systemName: "equal.circle")
                                .font(.title2)
                            Text("Aynı ünvanda")
                                .font(AppTypography.headline)
                            Spacer()
                            if terfiIleMi == false {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.white)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(terfiIleMi == false ? Color(hex: "8B5CF6") : appTheme.listRowBackground)
                        .foregroundColor(terfiIleMi == false ? .white : appTheme.textPrimary)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)

                if terfiIleMi == true {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Mevcut unvanınız nedir?")
                            .font(AppTypography.subheadline)
                            .bold()
                            .foregroundColor(appTheme.textPrimary)
                        Picker("Mevcut unvan", selection: Binding(
                            get: { mevcutUnvan?.id ?? "" },
                            set: { id in mevcutUnvan = unvanListesi.first { $0.id == id } }
                        )) {
                            Text("Seçiniz").tag("")
                            ForEach(unvanListesi) { u in
                                Text(u.ad).tag(u.id)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(appTheme.textPrimary)

                        Text("Teklifteki unvan nedir?")
                            .font(AppTypography.subheadline)
                            .bold()
                            .foregroundColor(appTheme.textPrimary)
                            .padding(.top, 8)
                        Picker("Teklif unvan", selection: Binding(
                            get: { teklifUnvan?.id ?? "" },
                            set: { id in teklifUnvan = unvanListesi.first { $0.id == id } }
                        )) {
                            Text("Seçiniz").tag("")
                            ForEach(unvanListesi) { u in
                                Text(u.ad).tag(u.id)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(appTheme.textPrimary)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 12).fill(appTheme.listRowBackground))
                    .padding(.horizontal, 16)
                }

                Button {
                    navigateToAnalysis = true
                } label: {
                    Text("Analizi Gör")
                        .font(AppTypography.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canShowAnalysis ? Color(hex: "3B82F6") : appTheme.textSecondary.opacity(0.5))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(!canShowAnalysis)
                .padding(.horizontal, 16)
                .padding(.top, 8)

                Spacer(minLength: 40)
            }
            .padding()
        }
        .navigationDestination(isPresented: $navigateToAnalysis) {
            KiyaslamaAnalysisView(
                currentSalaryOnlyMonthlyNets: currentSalaryOnlyMonthlyNets,
                offerSalaryOnlyMonthlyNets: offerSalaryOnlyMonthlyNets,
                currentWithPrimMonthlyNets: currentWithPrimMonthlyNets,
                offerWithPrimMonthlyNets: offerWithPrimMonthlyNets,
                currentCompany: currentCompany,
                offerCompany: offerCompany,
                currentWeeklyCommuteHours: currentWeeklyCommuteHours,
                offerWeeklyCommuteHours: offerWeeklyCommuteHours,
                terfiMevcutRank: terfiIleMi == true ? mevcutUnvan?.rank : nil,
                terfiMevcutKadem: terfiIleMi == true ? mevcutUnvan?.kademGrubu.displayName : nil,
                terfiTeklifRank: terfiIleMi == true ? teklifUnvan?.rank : nil,
                terfiTeklifKadem: terfiIleMi == true ? teklifUnvan?.kademGrubu.displayName : nil
            )
            .environmentObject(appTheme)
        }
        .navigationTitle("Pozisyon")
    }
}

// Analysis view shown after Devam — displays chart and monthly averages
struct KiyaslamaAnalysisView: View {
    @EnvironmentObject var appTheme: AppTheme
    let currentSalaryOnlyMonthlyNets: [Double]
    let offerSalaryOnlyMonthlyNets: [Double]
    let currentWithPrimMonthlyNets: [Double]
    let offerWithPrimMonthlyNets: [Double]
    let currentWeeklyCommuteHours: Double
    let offerWeeklyCommuteHours: Double
    let currentCompany: String
    let offerCompany: String
    let terfiMevcutRank: Int?
    let terfiMevcutKadem: String?
    let terfiTeklifRank: Int?
    let terfiTeklifKadem: String?
    
    init(currentSalaryOnlyMonthlyNets: [Double],
         offerSalaryOnlyMonthlyNets: [Double],
         currentWithPrimMonthlyNets: [Double],
         offerWithPrimMonthlyNets: [Double],
         currentCompany: String,
         offerCompany: String,
         currentWeeklyCommuteHours: Double,
         offerWeeklyCommuteHours: Double,
         terfiMevcutRank: Int? = nil,
         terfiMevcutKadem: String? = nil,
         terfiTeklifRank: Int? = nil,
         terfiTeklifKadem: String? = nil) {
        self.currentSalaryOnlyMonthlyNets = currentSalaryOnlyMonthlyNets
        self.offerSalaryOnlyMonthlyNets = offerSalaryOnlyMonthlyNets
        self.currentWithPrimMonthlyNets = currentWithPrimMonthlyNets
        self.offerWithPrimMonthlyNets = offerWithPrimMonthlyNets
        self.currentCompany = currentCompany
        self.offerCompany = offerCompany
        self.currentWeeklyCommuteHours = currentWeeklyCommuteHours
        self.offerWeeklyCommuteHours = offerWeeklyCommuteHours
        self.terfiMevcutRank = terfiMevcutRank
        self.terfiMevcutKadem = terfiMevcutKadem
        self.terfiTeklifRank = terfiTeklifRank
        self.terfiTeklifKadem = terfiTeklifKadem
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
    
    private var currentSalarySum: Double { currentSalaryOnlyMonthlyNets.reduce(0, +) }
    private var currentWithPrimSum: Double { currentWithPrimMonthlyNets.reduce(0, +) }
    private var offerSalarySum: Double { offerSalaryOnlyMonthlyNets.reduce(0, +) }
    private var offerWithPrimSum: Double { offerWithPrimMonthlyNets.reduce(0, +) }
    private var currentHasPrim: Bool { abs(currentWithPrimSum - currentSalarySum) > 1.0 }
    private var offerHasPrim: Bool { abs(offerWithPrimSum - offerSalarySum) > 1.0 }
    private var anyPrim: Bool { currentHasPrim || offerHasPrim }

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

    private var terfiGosterilebilir: Bool {
        guard let m = terfiMevcutRank, let t = terfiTeklifRank,
              let _ = terfiMevcutKadem, let _ = terfiTeklifKadem else { return false }
        return (1...5).contains(m) && (1...5).contains(t)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text("Teklif Analizi - Sonuç")
                    .font(AppTypography.title2)
                    .bold()
                    .foregroundColor(appTheme.textPrimary)

                if terfiGosterilebilir, let mRank = terfiMevcutRank, let tRank = terfiTeklifRank,
                   let mKadem = terfiMevcutKadem, let tKadem = terfiTeklifKadem {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Kıdem")
                            .font(AppTypography.subheadline)
                            .foregroundColor(appTheme.textSecondary)
                        Text("\(mRank) → \(tRank) (\(mKadem) → \(tKadem))")
                            .font(AppTypography.headline)
                            .foregroundColor(appTheme.textPrimary)
                        HStack(spacing: 4) {
                            ForEach(1...5, id: \.self) { step in
                                ZStack(alignment: .bottom) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(step <= mRank ? Color(hex: "3B82F6").opacity(0.3) : appTheme.cardBackgroundSecondary)
                                        .frame(height: 28)
                                    if step == mRank {
                                        Circle()
                                            .fill(Color(hex: "3B82F6"))
                                            .frame(width: 10, height: 10)
                                            .offset(y: 4)
                                    }
                                    if step == tRank {
                                        Circle()
                                            .stroke(Color(hex: "8B5CF6"), lineWidth: 2)
                                            .background(Circle().fill(Color(hex: "8B5CF6").opacity(0.4)))
                                            .frame(width: 14, height: 14)
                                            .offset(y: 4)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .frame(height: 36)
                        HStack {
                            HStack(spacing: 4) {
                                Circle().fill(Color(hex: "3B82F6")).frame(width: 8, height: 8)
                                Text("Mevcut").font(AppTypography.caption1).foregroundColor(appTheme.textSecondary)
                            }
                            Spacer()
                            HStack(spacing: 4) {
                                Circle().stroke(Color(hex: "8B5CF6"), lineWidth: 1.5).frame(width: 10, height: 10)
                                Text("Teklif").font(AppTypography.caption1).foregroundColor(appTheme.textSecondary)
                            }
                        }
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(appTheme.listRowBackground))
                    .padding(.horizontal, 16)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Maaş (Prim hariç)")
                        .font(AppTypography.subheadline)
                        .foregroundColor(appTheme.textSecondary)
                    SimpleInlineChart(current: currentSalaryOnlyMonthlyNets, offer: offerSalaryOnlyMonthlyNets, currentColor: Color(hex: "3B82F6"), offerColor: Color(hex: "8B5CF6"))
                        .frame(height: 200)
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

