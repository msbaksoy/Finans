// ================================================================
// KrediHesaplamaView_FINAL.swift
// ================================================================
// Bu dosya mevcut Views/KrediHesaplamaView.swift'in TAM YERİNE geçer.
// KrediViewModel, KrediCalculator, KrediHesapSonucu, HKrediTuru
// dokunulmadı — sadece View katmanı yenilendi.
//
// Düzeltilen:
//   - Hesapla butonuna basınca sonuç görünür, ödeme planı butonu
//     sonucun hemen altında, ScrollViewReader ile otomatik scroll
//
// Not: PressButtonStyle ContentView.swift içinde tanımlı (aynı hedef).
// ShareSheet bu modülde DeepKiyaslamaAnalysisView ile çakışmaması için
// KrediPDFShareSheet adıyla kullanılır.
// ================================================================

import SwiftUI
import UIKit

// MARK: ─ KrediHesaplamaView ────────────────────────────────────
struct KrediHesaplamaView: View {
    @EnvironmentObject var appTheme: AppTheme
    @EnvironmentObject var krediConfig: KrediConfigService
    @StateObject private var vm = KrediViewModel()

    @State private var gorundu = false
    @State private var pdfPaylas = false
    @State private var pdfURL: URL? = nil

    private let sonucID = "sonucSatir"
    private let odemeID = "odemeSatir"

    var body: some View {
        ZStack {
            appTheme.backgroundMain.ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        heroAlani
                        mainIcerik(proxy: proxy)
                            .padding(.horizontal, 18)
                            .padding(.top, 20)
                        Color.clear.frame(height: 52)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .navigationTitle("Kredi Simülatörü")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    vm.isRefreshing = true
                    Task { await krediConfig.refresh(); vm.isRefreshing = false }
                } label: {
                    if vm.isRefreshing {
                        ProgressView().tint(vm.secilenTur.renk)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(vm.secilenTur.renk)
                    }
                }
                .disabled(vm.isRefreshing)
            }
        }
        .sheet(isPresented: $pdfPaylas) {
            if let url = pdfURL {
                KrediPDFShareSheet(items: [url])
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation { gorundu = true }
            }
        }
    }

    // MARK: ── Hero
    private var heroAlani: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [
                    vm.secilenTur.renk.opacity(appTheme.isLight ? 0.10 : 0.18),
                    appTheme.backgroundMain,
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 128)
            .animation(.easeInOut(duration: 0.3), value: vm.secilenTur)

            Circle()
                .fill(vm.secilenTur.renk.opacity(0.12))
                .frame(width: 200)
                .blur(radius: 35)
                .offset(x: UIScreen.main.bounds.width * 0.58, y: -30)
                .animation(.easeInOut(duration: 0.3), value: vm.secilenTur)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: vm.secilenTur.icon)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(vm.secilenTur.renk)
                    Text((vm.secilenTur.label + " KREDİSİ").uppercased())
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(vm.secilenTur.renk)
                        .tracking(1.5)
                }
                Text("Ne kadar ödersiniz?")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundColor(appTheme.textPrimary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
        }
        .frame(height: 128)
        .opacity(gorundu ? 1 : 0)
        .animation(.easeOut(duration: 0.4), value: gorundu)
    }

    // MARK: ── Ana İçerik (ScrollViewReader proxy alır)
    @ViewBuilder
    private func mainIcerik(proxy: ScrollViewProxy) -> some View {
        VStack(spacing: 20) {
            turSecici
                .opacity(gorundu ? 1 : 0)
                .offset(y: gorundu ? 0 : 12)
                .animation(.spring(response: 0.5).delay(0.06), value: gorundu)

            girisFormu
                .opacity(gorundu ? 1 : 0)
                .offset(y: gorundu ? 0 : 12)
                .animation(.spring(response: 0.5).delay(0.12), value: gorundu)

            hesaplaButon(proxy: proxy)
                .opacity(gorundu ? 1 : 0)
                .animation(.spring(response: 0.5).delay(0.18), value: gorundu)

            if let s = vm.sonuc {
                sonucKarti(s)
                    .id(sonucID)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity
                        ))

                aksiyonButonlari(proxy: proxy)
                    .transition(.opacity)

                if vm.odemeGoster {
                    odemePlanView(s)
                        .id(odemeID)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }

    // MARK: ── Tür Seçici
    private var turSecici: some View {
        HStack(spacing: 10) {
            ForEach(HKrediTuru.allCases, id: \.label) { tur in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        vm.turSecildi(tur)
                    }
                } label: {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(vm.secilenTur == tur ? tur.renk : tur.renk.opacity(0.10))
                                .frame(width: 48, height: 48)
                                .shadow(
                                    color: vm.secilenTur == tur ? tur.renk.opacity(0.45) : .clear,
                                    radius: 8,
                                    y: 3
                                )
                            Image(systemName: tur.icon)
                                .font(.system(size: 19, weight: .semibold))
                                .foregroundColor(vm.secilenTur == tur ? .white : tur.renk)
                        }
                        Text(tur.label)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(vm.secilenTur == tur ? tur.renk : appTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(appTheme.cardSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(
                                        vm.secilenTur == tur ? tur.renk.opacity(0.55) : appTheme.cardStroke.opacity(0.3),
                                        lineWidth: vm.secilenTur == tur ? 2 : 1
                                    )
                            )
                    )
                    .shadow(color: vm.secilenTur == tur ? tur.renk.opacity(0.10) : .clear, radius: 10, y: 4)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: ── Giriş Formu
    private var girisFormu: some View {
        VStack(spacing: 14) {
            formAlani(
                baslik: "Kredi Tutarı",
                ikon: "turkishlirasign.circle.fill",
                text: $vm.anaparaText,
                placeholder: "0",
                suffix: "₺",
                keyboard: .decimalPad
            )

            HStack(spacing: 12) {
                formAlani(
                    baslik: "Vade",
                    ikon: "calendar",
                    text: $vm.vadeText,
                    placeholder: vm.secilenTur == .konut ? "120" : "12",
                    suffix: "Ay",
                    keyboard: .numberPad
                )
                formAlani(
                    baslik: "Aylık Faiz",
                    ikon: "percent",
                    text: $vm.faizText,
                    placeholder: "4,99",
                    suffix: "%",
                    keyboard: .decimalPad
                )
            }

            if vm.secilenTur != .konut {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(vm.secilenTur.renk.opacity(0.7))
                    Text("KKDF %\(Int(krediConfig.config.kkdfOrani * 100))  ·  BSMV %\(Int(krediConfig.config.bsmvOrani * 100)) vergileri dahil")
                        .font(.system(size: 11))
                        .foregroundColor(appTheme.textSecondary)
                }
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(vm.secilenTur.renk.opacity(0.07))
                .cornerRadius(10)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(18)
        .background(appTheme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(vm.secilenTur.renk.opacity(0.18), lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(appTheme.isLight ? 0.04 : 0), radius: 12, y: 4)
        .animation(.easeInOut(duration: 0.2), value: vm.secilenTur)
    }

    private func formAlani(
        baslik: String, ikon: String, text: Binding<String>,
        placeholder: String, suffix: String, keyboard: UIKeyboardType
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 5) {
                Image(systemName: ikon)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(vm.secilenTur.renk)
                Text(baslik)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(appTheme.textSecondary)
            }
            HStack {
                TextField(placeholder, text: text)
                    .keyboardType(keyboard)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(appTheme.textPrimary)
                    .monospacedDigit()
                    .onChange(of: text.wrappedValue) { _, newValue in
                        guard keyboard == .decimalPad || keyboard == .numberPad else { return }
                        guard suffix == "₺" else { return }
                        let onlyDigits = newValue.filter { $0.isNumber }
                        if let num = Int(onlyDigits), num > 0 {
                            let f = NumberFormatter()
                            f.locale = Locale(identifier: "tr_TR")
                            f.numberStyle = .decimal
                            f.maximumFractionDigits = 0
                            let formatted = f.string(from: NSNumber(value: num)) ?? newValue
                            if formatted != newValue { text.wrappedValue = formatted }
                        } else if onlyDigits.isEmpty {
                            text.wrappedValue = ""
                        }
                    }
                Spacer(minLength: 8)
                Text(suffix)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(vm.secilenTur.renk.opacity(0.8))
            }
            .padding(.horizontal, 12).padding(.vertical, 12)
            .background(
                appTheme.isLight
                    ? Color(white: 0.965)
                    : Color.white.opacity(0.06)
            )
            .clipShape(RoundedRectangle(cornerRadius: 13))
            .overlay(
                RoundedRectangle(cornerRadius: 13)
                    .stroke(vm.secilenTur.renk.opacity(0.22), lineWidth: 1.2)
            )
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: ── Hesapla Butonu
    private func hesaplaButon(proxy: ScrollViewProxy) -> some View {
        Button {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                            to: nil, from: nil, for: nil)
            withAnimation(.spring(response: 0.4)) {
                vm.hesapla(krediConfig: krediConfig)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.40) {
                withAnimation(.easeOut(duration: 0.3)) {
                    proxy.scrollTo(sonucID, anchor: .top)
                }
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "equal.circle.fill")
                    .font(.system(size: 18, weight: .bold))
                Text("Hesapla")
                    .font(.system(size: 17, weight: .bold))
                Spacer()
                Image(systemName: "chevron.down.circle.fill")
                    .font(.system(size: 15))
                    .opacity(0.7)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 22).padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [vm.secilenTur.renk, vm.secilenTur.renk.opacity(0.78)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: vm.secilenTur.renk.opacity(0.42), radius: 14, y: 6)
        }
        .buttonStyle(PressButtonStyle())
        .animation(.easeInOut(duration: 0.2), value: vm.secilenTur)
    }

    // MARK: ── Sonuç Kartı
    private func sonucKarti(_ s: KrediHesapSonucu) -> some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "060D1F"), vm.secilenTur.renk.opacity(0.38)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))

            Circle()
                .fill(vm.secilenTur.renk.opacity(0.20))
                .frame(width: 200)
                .blur(radius: 38)
                .offset(x: UIScreen.main.bounds.width * 0.35, y: -30)

            Image(systemName: vm.secilenTur.icon)
                .font(.system(size: 100, weight: .black))
                .foregroundColor(.white.opacity(0.035))
                .offset(x: UIScreen.main.bounds.width * 0.40, y: 20)

            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 5) {
                    Image(systemName: vm.secilenTur.icon)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(vm.secilenTur.renk)
                    Text((vm.secilenTur.label + " KREDİSİ").uppercased())
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(vm.secilenTur.renk)
                        .tracking(1.4)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("AYLIK TAKSİT")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.42))
                        .tracking(1.2)
                    Text(formatTL(s.aylikTaksit))
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .monospacedDigit()
                }

                HStack(spacing: 0) {
                    metrik("Toplam Faiz", formatTLKisa(s.toplamFaiz), Color(hex: "F59E0B"))
                    Divider().background(Color.white.opacity(0.12)).padding(.vertical, 10)
                    metrik("Toplam Maliyet", formatTLKisa(s.toplamMaliyet), Color(hex: "34D399"))
                    Divider().background(Color.white.opacity(0.12)).padding(.vertical, 10)
                    metrik("Vade", vm.vadeText + " Ay", Color(hex: "60A5FA"))
                }
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                // "Toplam maliyetin faiz/vergilerden oluşan oranı" hesaplaması
                let yuk = s.toplamFaiz / max(1, s.toplamMaliyet) * 100
                HStack(spacing: 6) {
                    Image(systemName: yuk > 50 ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(yuk > 50 ? Color(hex: "F59E0B") : Color(hex: "34D399"))
                    Text(String(format: "Toplam maliyetin %.1f%%'si faiz ve vergilerden oluşuyor", yuk))
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.52))
                }
            }
            .padding(22)
        }
        .shadow(color: vm.secilenTur.renk.opacity(0.32), radius: 22, y: 8)
        .animation(.easeInOut(duration: 0.2), value: vm.secilenTur)
    }

    private func metrik(_ baslik: String, _ deger: String, _ renk: Color) -> some View {
        VStack(spacing: 3) {
            Text(baslik)
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.42))
            Text(deger)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundColor(renk)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 11)
    }

    // MARK: ── Aksiyon Butonları (ödeme planı + PDF)
    private func aksiyonButonlari(proxy: ScrollViewProxy) -> some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.35)) {
                    vm.odemeGoster.toggle()
                }
                if vm.odemeGoster {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
                        withAnimation { proxy.scrollTo(odemeID, anchor: .top) }
                    }
                }
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: vm.odemeGoster
                        ? "chevron.up.circle.fill"
                        : "list.bullet.rectangle.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text(vm.odemeGoster ? "Planı Kapat" : "Ödeme Planı")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(vm.secilenTur.renk)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(vm.secilenTur.renk.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(vm.secilenTur.renk.opacity(0.35), lineWidth: 1.5)
                )
            }
            .buttonStyle(PressButtonStyle())

            Button { pdfOlusturVePaylas() } label: {
                HStack(spacing: 7) {
                    Image(systemName: "square.and.arrow.up.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text("PDF")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(vm.secilenTur.renk)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: vm.secilenTur.renk.opacity(0.38), radius: 8, y: 3)
            }
            .buttonStyle(PressButtonStyle())
        }
    }

    // MARK: ── Ödeme Planı Tablosu
    private func odemePlanView(_ s: KrediHesapSonucu) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "tablecells.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(vm.secilenTur.renk)
                Text("Ödeme Planı")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(appTheme.textPrimary)
                Spacer()
                let adet = s.tuketiciPlan?.count ?? s.konutPlan?.count ?? 0
                Text("\(adet) taksit")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(appTheme.textSecondary)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(vm.secilenTur.renk.opacity(0.10))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 16).padding(.vertical, 14)

            Rectangle()
                .fill(appTheme.cardStroke.opacity(0.35))
                .frame(height: 0.5)

            ScrollView(.horizontal, showsIndicators: false) {
                VStack(spacing: 0) {
                    tabloBaslikSatiri(vergiVar: vm.secilenTur != .konut)

                    if let plan = s.tuketiciPlan {
                        ForEach(Array(plan.enumerated()), id: \.element.id) { idx, satir in
                            tuketiciSatiri(satir, idx: idx)
                            if idx < plan.count - 1 {
                                Divider().opacity(0.15)
                            }
                        }
                    } else if let plan = s.konutPlan {
                        ForEach(Array(plan.enumerated()), id: \.element.id) { idx, satir in
                            konutSatiri(satir, idx: idx)
                            if idx < plan.count - 1 {
                                Divider().opacity(0.15)
                            }
                        }
                    }
                }
            }
        }
        .background(appTheme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(vm.secilenTur.renk.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: .black.opacity(appTheme.isLight ? 0.04 : 0), radius: 12, y: 4)
    }

    private func tabloBaslikSatiri(vergiVar: Bool) -> some View {
        HStack(spacing: 0) {
            Text("No")
                .frame(width: 42, alignment: .center)
            Text("Taksit")
                .frame(width: 90, alignment: .trailing)
            Text("Anapara")
                .frame(width: 90, alignment: .trailing)
            Text("Faiz")
                .frame(width: 80, alignment: .trailing)
            if vergiVar {
                Text("KKDF+BSMV")
                    .frame(width: 90, alignment: .trailing)
            }
            Text("Kalan")
                .frame(width: 100, alignment: .trailing)
        }
        .font(.system(size: 10, weight: .bold))
        .foregroundColor(appTheme.textSecondary)
        .padding(.horizontal, 14).padding(.vertical, 11)
        .background(vm.secilenTur.renk.opacity(0.09))
        .frame(minWidth: vergiVar ? 510 : 416)
    }

    private func tuketiciSatiri(_ s: KrediCalculator.OdemeSatiri, idx: Int) -> some View {
        HStack(spacing: 0) {
            Text("\(s.taksitNo)")
                .frame(width: 42, alignment: .center)
                .foregroundColor(appTheme.textSecondary)
            Text(tfmt(s.taksitTutari))
                .frame(width: 90, alignment: .trailing)
                .foregroundColor(appTheme.textPrimary)
            Text(tfmt(s.anapara))
                .frame(width: 90, alignment: .trailing)
                .foregroundColor(Color(hex: "10B981"))
            Text(tfmt(s.faiz))
                .frame(width: 80, alignment: .trailing)
                .foregroundColor(appTheme.textSecondary)
            Text(tfmt(s.kkdf + s.bsmv))
                .frame(width: 90, alignment: .trailing)
                .foregroundColor(Color(hex: "F59E0B"))
            Text(tfmt(s.kalanAnapara))
                .frame(width: 100, alignment: .trailing)
                .foregroundColor(appTheme.textPrimary)
        }
        .font(.system(size: 11, design: .monospaced))
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(
            idx.isMultiple(of: 2)
                ? vm.secilenTur.renk.opacity(0.03)
                : Color.clear
        )
        .frame(minWidth: 510)
    }

    private func konutSatiri(_ s: KrediCalculator.KonutOdemeSatiri, idx: Int) -> some View {
        HStack(spacing: 0) {
            Text("\(s.taksitNo)")
                .frame(width: 42, alignment: .center)
                .foregroundColor(appTheme.textSecondary)
            Text(tfmt(s.taksitTutari))
                .frame(width: 90, alignment: .trailing)
                .foregroundColor(appTheme.textPrimary)
            Text(tfmt(s.anapara))
                .frame(width: 90, alignment: .trailing)
                .foregroundColor(Color(hex: "10B981"))
            Text(tfmt(s.faiz))
                .frame(width: 80, alignment: .trailing)
                .foregroundColor(appTheme.textSecondary)
            Text(tfmt(s.kalanAnapara))
                .frame(width: 100, alignment: .trailing)
                .foregroundColor(appTheme.textPrimary)
        }
        .font(.system(size: 11, design: .monospaced))
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(
            idx.isMultiple(of: 2)
                ? vm.secilenTur.renk.opacity(0.03)
                : Color.clear
        )
        .frame(minWidth: 416)
    }

    // MARK: ── PDF
    private func pdfOlusturVePaylas() {
        guard let s = vm.sonuc else { return }
        let data: Data?
        if let plan = s.tuketiciPlan {
            switch vm.secilenTur {
            case .tuketici:
                data = KrediPdfOlusturucu.tuketiciPdf(
                    anapara: vm.anaparaText, vade: vm.vadeText, faiz: vm.faizText,
                    plan: plan, aylikTaksit: s.aylikTaksit,
                    toplamFaiz: s.toplamFaiz, toplamMaliyet: s.toplamMaliyet)
            case .tasit:
                data = KrediPdfOlusturucu.tasitPdf(
                    anapara: vm.anaparaText, vade: vm.vadeText, faiz: vm.faizText,
                    plan: plan, aylikTaksit: s.aylikTaksit,
                    toplamFaiz: s.toplamFaiz, toplamMaliyet: s.toplamMaliyet)
            case .konut:
                data = nil
            }
        } else if let plan = s.konutPlan {
            data = KrediPdfOlusturucu.konutPdf(
                anapara: vm.anaparaText, vade: vm.vadeText, faiz: vm.faizText,
                plan: plan)
        } else {
            data = nil
        }

        guard let pdf = data else { return }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("KrediPlan.pdf")
        try? pdf.write(to: url)
        pdfURL = url
        pdfPaylas = true
    }

    // MARK: ── Formatters
    private func formatTL(_ d: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: "tr_TR")
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return (f.string(from: NSNumber(value: d)) ?? "0") + " ₺"
    }

    private func formatTLKisa(_ d: Double) -> String {
        if d >= 1_000_000 { return String(format: "%.1fM ₺", d / 1_000_000) }
        if d >= 1_000 { return String(format: "%.0fK ₺", d / 1_000) }
        return String(format: "%.0f ₺", d)
    }

    private func tfmt(_ d: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: "tr_TR")
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: d)) ?? "0,00"
    }
}

// MARK: ─ Paylaşım Sheet (modüldeki diğer ShareSheet ile çakışmaz)
struct KrediPDFShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

// MARK: ─ Eski OrtakTabloSatiri / OrtakKrediTablosu (geriye dönük uyumluluk)
struct OrtakTabloSatiri: Identifiable {
    let id = UUID()
    let no: Int
    let taksit: Double
    let anapara: Double
    let faiz: Double
    let kkdf: Double?
    let bsmv: Double?
    let kalan: Double
}

struct OrtakKrediTablosu: View {
    @EnvironmentObject var appTheme: AppTheme
    let satirlar: [OrtakTabloSatiri]
    let vergiVar: Bool
    let temaRengi: Color

    var body: some View { EmptyView() }
}

// MARK: ─ Preview ───────────────────────────────────────────────
#Preview {
    NavigationStack {
        KrediHesaplamaView()
            .environmentObject(AppTheme())
            .environmentObject(KrediConfigService.shared)
    }
}
