// ================================================================
// IKDesignSystem.swift
// ================================================================
// Global tasarım sistemi — TÜM EKRANLARDA kullanılır.
// ContentView.swift içindeki PressButtonStyle / BouncyButtonStyle /
// ScaleButtonStyle buraya taşındı.
// ================================================================

import SwiftUI
import UIKit

// MARK: ─ Spacing & Radius Tokens ─────────────────────────────
enum DS {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let base: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32

    static let rSM: CGFloat = 10
    static let rMD: CGFloat = 14
    static let rLG: CGFloat = 18
    static let rXL: CGFloat = 22
    static let rFull: CGFloat = 999

    static let btnH: CGFloat = 52
    static let btnHSM: CGFloat = 44
    static let btnFont: CGFloat = 15
    static let btnRadius: CGFloat = 16

    static let iconSM: CGFloat = 36
    static let iconMD: CGFloat = 44
    static let iconLG: CGFloat = 52

    static let heroH: CGFloat = 160

    static let hPad: CGFloat = 18
}

// MARK: ─ Button Styles ────────────────────────────────────────

/// Tüm basılabilir etkileşimler için standart press efekti
struct PressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.90 : 1.0)
            .animation(.spring(response: 0.20, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Alias — geriye dönük uyumluluk
typealias BouncyButtonStyle = PressButtonStyle
typealias ScaleButtonStyle = PressButtonStyle

// MARK: ─ Primary Button ───────────────────────────────────────

struct IKPrimaryButton: View {
    let title: String
    let icon: String?
    let color: Color
    let action: () -> Void
    var fullWidth = true
    var height: CGFloat = DS.btnH

    init(_ title: String, icon: String? = nil, color: Color = Color(hex: "3B82F6"),
         fullWidth: Bool = true, height: CGFloat = DS.btnH, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.color = color
        self.fullWidth = fullWidth
        self.height = height
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let ic = icon {
                    Image(systemName: ic)
                        .font(.system(size: 15, weight: .bold))
                }
                Text(title)
                    .font(.system(size: DS.btnFont, weight: .bold))
                    .lineLimit(1)
            }
            .foregroundColor(.white)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: height)
            .padding(.horizontal, fullWidth ? 0 : 20)
            .background(
                LinearGradient(colors: [color, color.opacity(0.82)],
                               startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: DS.btnRadius, style: .continuous))
            .shadow(color: color.opacity(0.35), radius: 10, y: 4)
        }
        .buttonStyle(PressButtonStyle())
    }
}

struct IKSecondaryButton: View {
    let title: String
    let icon: String?
    let color: Color
    let action: () -> Void
    var height: CGFloat = DS.btnH

    init(_ title: String, icon: String? = nil, color: Color = Color(hex: "3B82F6"),
         height: CGFloat = DS.btnH, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.color = color
        self.height = height
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let ic = icon {
                    Image(systemName: ic)
                        .font(.system(size: 14, weight: .bold))
                }
                Text(title)
                    .font(.system(size: DS.btnFont, weight: .bold))
                    .lineLimit(1)
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(color.opacity(0.09))
            .clipShape(RoundedRectangle(cornerRadius: DS.btnRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.btnRadius, style: .continuous)
                    .stroke(color.opacity(0.35), lineWidth: 1.5)
            )
        }
        .buttonStyle(PressButtonStyle())
    }
}

// MARK: ─ Card ─────────────────────────────────────────────────
struct IKCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = DS.base
    var cornerRadius: CGFloat = DS.rXL
    var strokeColor: Color = .clear
    @EnvironmentObject var appTheme: AppTheme

    init(padding: CGFloat = DS.base, cornerRadius: CGFloat = DS.rXL,
         strokeColor: Color = .clear, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.strokeColor = strokeColor
    }

    var body: some View {
        content
            .padding(padding)
            .background(appTheme.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(strokeColor.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: .black.opacity(appTheme.isLight ? 0.04 : 0), radius: 10, y: 3)
    }
}

// MARK: ─ Section Header ──────────────────────────────────────
struct IKSectionHeader: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(color)
            Text(title.uppercased())
                .font(.system(size: 11, weight: .black))
                .foregroundColor(Color(hex: "94A3B8"))
                .tracking(1.5)
            Spacer()
        }
    }
}

// MARK: ─ Form Field ───────────────────────────────────────────
struct IKFormField: View {
    let label: String
    let icon: String
    let color: Color
    @Binding var text: String
    let placeholder: String
    let suffix: String
    let keyboard: UIKeyboardType
    @EnvironmentObject var appTheme: AppTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(color)
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(appTheme.textSecondary)
            }
            HStack {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboard)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(appTheme.textPrimary)
                    .monospacedDigit()
                if !suffix.isEmpty {
                    Spacer(minLength: 6)
                    Text(suffix)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(color.opacity(0.75))
                }
            }
            .padding(.horizontal, DS.md)
            .padding(.vertical, 13)
            .background(appTheme.isLight ? Color(white: 0.965) : Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: DS.rMD, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.rMD, style: .continuous)
                    .stroke(color.opacity(0.22), lineWidth: 1.2)
            )
        }
    }
}

// MARK: ─ Hero Background ─────────────────────────────────────
struct IKHero: View {
    let colors: [Color]
    let title: String
    let subtitle: String
    let icon: String
    let badge: String?
    var height: CGFloat = DS.heroH

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                .frame(height: height)

            Circle()
                .fill(colors.first?.opacity(0.25) ?? Color.blue.opacity(0.15))
                .frame(width: 180)
                .blur(radius: 35)
                .offset(x: UIScreen.main.bounds.width * 0.58, y: -20)

            Image(systemName: icon)
                .font(.system(size: 110, weight: .black))
                .foregroundColor(.white.opacity(0.035))
                .offset(x: UIScreen.main.bounds.width * 0.44, y: 10)

            VStack(alignment: .leading, spacing: 6) {
                if let b = badge {
                    HStack(spacing: 5) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 9, weight: .bold))
                        Text(b)
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(Color(hex: "A78BFA"))
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Color(hex: "A78BFA").opacity(0.15))
                    .clipShape(Capsule())
                }

                Text(title)
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)

                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.60))
                        .lineLimit(2)
                }
            }
            .padding(.horizontal, DS.lg)
            .padding(.bottom, 20)
        }
        .frame(height: height)
    }
}

// MARK: ─ Metric Badge ────────────────────────────────────────
struct IKMetricBadge: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.42))
            Text(value)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundColor(color)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }
}

// MARK: ─ Chip Selector ───────────────────────────────────────
struct IKChipSelector<T: Hashable>: View {
    let options: [T]
    @Binding var selected: T
    let label: (T) -> String
    let color: Color
    @EnvironmentObject var appTheme: AppTheme

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(options, id: \.self) { opt in
                    let sel = selected == opt
                    Button {
                        withAnimation(.spring(response: 0.25)) { selected = opt }
                    } label: {
                        Text(label(opt))
                            .font(.system(size: 13, weight: sel ? .bold : .medium))
                            .foregroundColor(sel ? .white : appTheme.textSecondary)
                            .padding(.horizontal, 14).padding(.vertical, 9)
                            .background(sel ? color : (appTheme.isLight ? Color(white: 0.95) : Color.white.opacity(0.07)))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(sel ? color.opacity(0.5) : Color.clear, lineWidth: 1.5))
                            .shadow(color: sel ? color.opacity(0.3) : .clear, radius: 5, y: 2)
                    }
                    .buttonStyle(PressButtonStyle())
                }
            }
        }
    }
}

// MARK: ─ Month Pill Selector ─────────────────────────────────
struct IKMonthSelector: View {
    @Binding var selectedMonth: Int
    let color: Color
    @EnvironmentObject var appTheme: AppTheme
    private let months = ["Oca", "Şub", "Mar", "Nis", "May", "Haz", "Tem", "Ağu", "Eyl", "Eki", "Kas", "Ara"]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                Color.clear.frame(width: DS.hPad - 7)
                ForEach(1...12, id: \.self) { m in
                    let sel = selectedMonth == m
                    Button {
                        withAnimation(.spring(response: 0.25)) { selectedMonth = m }
                    } label: {
                        VStack(spacing: 2) {
                            Text(months[m - 1])
                                .font(.system(size: 12, weight: sel ? .bold : .medium))
                                .foregroundColor(sel ? .white : appTheme.textSecondary)
                            Text("\(m)")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(sel ? .white.opacity(0.75) : appTheme.textSecondary.opacity(0.5))
                        }
                        .frame(width: 46, height: 42)
                        .background(sel ? color : (appTheme.isLight ? Color(white: 0.95) : Color.white.opacity(0.07)))
                        .clipShape(RoundedRectangle(cornerRadius: DS.rSM, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.rSM, style: .continuous)
                                .stroke(sel ? color.opacity(0.5) : Color.clear, lineWidth: 1.5)
                        )
                        .shadow(color: sel ? color.opacity(0.3) : .clear, radius: 5, y: 2)
                    }
                    .buttonStyle(PressButtonStyle())
                }
                Color.clear.frame(width: DS.hPad - 7)
            }
        }
    }
}

// MARK: ─ Sticky Bottom Bar ───────────────────────────────────
struct IKStickyBar: View {
    @EnvironmentObject var appTheme: AppTheme
    let content: AnyView
    var safeAreaPad: CGFloat = 28

    var body: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [appTheme.backgroundMain.opacity(0), appTheme.backgroundMain],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 24)
            .allowsHitTesting(false)

            content
                .padding(.horizontal, DS.lg)
                .padding(.bottom, safeAreaPad)
                .background(appTheme.backgroundMain)
        }
    }
}
