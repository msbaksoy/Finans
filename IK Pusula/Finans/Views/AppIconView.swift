// ================================================================
// AppIconView.swift — İK PUSULA
// ================================================================
// KULLANIM:
//   1. Views/AppIconView.swift ile değiştir
//   2. Xcode Preview'da aç → 1024×1024 screenshot al
//   3. Assets.xcassets → AppIcon → 1024×1024 alanına sürükle
// ================================================================

import SwiftUI

struct AppIconView: View {
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            IKPusulaIcon(size: size)
                .frame(width: size, height: size)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - Ana İkon
private struct IKPusulaIcon: View {
    let size: CGFloat
    private var s: CGFloat { size / 1024 }

    // Renk paleti
    private let navy0  = Color(red: 0.024, green: 0.051, blue: 0.122) // #060D1F
    private let navy1  = Color(red: 0.039, green: 0.094, blue: 0.196) // #0A1832
    private let navy2  = Color(red: 0.027, green: 0.078, blue: 0.157) // #071428

    private let gold0  = Color(red: 1.000, green: 0.969, blue: 0.627) // #FFF0A0 — parlak tepe
    private let gold1  = Color(red: 0.969, green: 0.832, blue: 0.298) // #F7D44C — ana altın
    private let gold2  = Color(red: 0.941, green: 0.737, blue: 0.180) // #F0BC2E — orta
    private let gold3  = Color(red: 0.545, green: 0.376, blue: 0.000) // #8B6000 — koyu
    private let gold4  = Color(red: 0.722, green: 0.525, blue: 0.043) // #B8860B — dip

    // Pusula merkezi (1024 koordinat uzayında)
    private let cx: CGFloat = 512
    private let cy: CGFloat = 490

    var body: some View {
        Canvas { ctx, _ in
            let size = self.size
            let s    = self.s

            // ─── 1. ZEMİN ───────────────────────────────────────────
            let bgRect = CGRect(x: 0, y: 0, width: size, height: size)
            let bgRadius = 225 * s
            let bgPath   = Path(roundedRect: bgRect, cornerRadius: bgRadius)

            ctx.fill(bgPath, with: .linearGradient(
                Gradient(stops: [
                    .init(color: navy0, location: 0.00),
                    .init(color: navy1, location: 0.55),
                    .init(color: navy2, location: 1.00)
                ]),
                startPoint: .zero,
                endPoint: CGPoint(x: size, y: size)
            ))

            // ─── 2. ARKA PLAN IŞIMASI ───────────────────────────────
            // Mavi halo — merkez
            ctx.drawLayer { lCtx in
                let haloCenter = CGPoint(x: cx * s, y: cy * s)
                lCtx.fill(
                    Path(ellipseIn: CGRect(
                        x: haloCenter.x - 260*s, y: haloCenter.y - 240*s,
                        width: 520*s, height: 480*s)),
                    with: .radialGradient(
                        Gradient(stops: [
                            .init(color: Color(red:0.102,green:0.227,blue:0.561).opacity(0.55), location: 0),
                            .init(color: .clear, location: 1)
                        ]),
                        center: haloCenter,
                        startRadius: 0, endRadius: 280*s
                    )
                )
            }

            // Altın halo — iğne kuzeyinde
            ctx.drawLayer { lCtx in
                let haloGold = CGPoint(x: cx * s, y: (cy - 200) * s)
                lCtx.fill(
                    Path(ellipseIn: CGRect(
                        x: haloGold.x - 200*s, y: haloGold.y - 180*s,
                        width: 400*s, height: 360*s)),
                    with: .radialGradient(
                        Gradient(stops: [
                            .init(color: gold2.opacity(0.20), location: 0),
                            .init(color: .clear, location: 1)
                        ]),
                        center: haloGold,
                        startRadius: 0, endRadius: 200*s
                    )
                )
            }

            // ─── 3. DIŞ KADRAN ÇEMBERİ ─────────────────────────────
            let outerR: CGFloat = 340 * s
            let midR:   CGFloat = 272 * s
            let innerR: CGFloat = 60  * s
            let center = CGPoint(x: cx * s, y: cy * s)

            // Dış daire
            ctx.stroke(
                Path(ellipseIn: CGRect(
                    x: center.x - outerR, y: center.y - outerR,
                    width: outerR*2, height: outerR*2)),
                with: .color(gold2.opacity(0.18)),
                lineWidth: 1.4 * s
            )
            // İç daire
            ctx.stroke(
                Path(ellipseIn: CGRect(
                    x: center.x - midR, y: center.y - midR,
                    width: midR*2, height: midR*2)),
                with: .color(gold2.opacity(0.10)),
                lineWidth: 0.8 * s
            )

            // ─── 4. KADRAN TIK ÇİZGİLERİ ───────────────────────────
            let angles: [(angle: Double, length: CGFloat, width: CGFloat, opacity: Double)] = [
                (0,    22, 3.2, 0.90),  // Kuzey — kalın
                (90,   14, 2.0, 0.35),  // Doğu
                (180,  14, 2.0, 0.35),  // Güney
                (270,  14, 2.0, 0.35),  // Batı
                (45,   10, 1.2, 0.22),
                (135,  10, 1.2, 0.22),
                (225,  10, 1.2, 0.22),
                (315,  10, 1.2, 0.22),
                (22.5,  7, 0.8, 0.14),
                (67.5,  7, 0.8, 0.14),
                (112.5, 7, 0.8, 0.14),
                (157.5, 7, 0.8, 0.14),
                (202.5, 7, 0.8, 0.14),
                (247.5, 7, 0.8, 0.14),
                (292.5, 7, 0.8, 0.14),
                (337.5, 7, 0.8, 0.14),
            ]

            for tick in angles {
                let rad = tick.angle * .pi / 180
                let outerPt = CGPoint(
                    x: center.x + outerR * CGFloat(sin(rad)),
                    y: center.y - outerR * CGFloat(cos(rad))
                )
                let innerPt = CGPoint(
                    x: center.x + (outerR - tick.length * s) * CGFloat(sin(rad)),
                    y: center.y - (outerR - tick.length * s) * CGFloat(cos(rad))
                )
                var p = Path()
                p.move(to: outerPt)
                p.addLine(to: innerPt)
                ctx.stroke(p, with: .color(gold1.opacity(tick.opacity)),
                           style: StrokeStyle(lineWidth: tick.width * s, lineCap: .round))
            }

            // ─── 5. "N" KARDİNAL NOKTASI ───────────────────────────
            let nY = (cy - 388) * s
            // N harfi için küçük platform
            ctx.fill(
                Path(roundedRect: CGRect(
                    x: cx*s - 28*s, y: nY - 36*s,
                    width: 56*s, height: 56*s), cornerRadius: 10*s),
                with: .linearGradient(
                    Gradient(colors: [gold1.opacity(0.22), gold3.opacity(0.12)]),
                    startPoint: CGPoint(x: cx*s, y: nY - 36*s),
                    endPoint: CGPoint(x: cx*s, y: nY + 20*s)
                )
            )
            // N metni Canvas'ta çizilemez — SF Symbol'le yapacağız
            // Bunun yerine küçük kuzey yıldızı
            drawStar(ctx: ctx, cx: cx*s, cy: nY - 8*s, r: 14*s, s: s, color: gold0)

            // ─── 6. PUSULA İĞNESİ ──────────────────────────────────
            // Kuzey (altın) yarısı
            let needleN = Path { p in
                p.move(to: CGPoint(x: cx*s, y: cy*s))
                p.addLine(to: CGPoint(x: (cx - 58)*s, y: (cy - 10)*s))
                p.addLine(to: CGPoint(x: cx*s, y: (cy - 302)*s))
                p.addLine(to: CGPoint(x: (cx + 58)*s, y: (cy - 10)*s))
                p.closeSubpath()
            }
            ctx.fill(needleN, with: .linearGradient(
                Gradient(stops: [
                    .init(color: gold0, location: 0.00),
                    .init(color: gold1, location: 0.35),
                    .init(color: gold2, location: 0.70),
                    .init(color: gold3, location: 1.00)
                ]),
                startPoint: CGPoint(x: cx*s, y: (cy - 302)*s),
                endPoint: CGPoint(x: cx*s, y: cy*s)
            ))

            // İğne sol kenar parlaklık şeridi
            ctx.fill(Path { p in
                p.move(to: CGPoint(x: cx*s, y: cy*s))
                p.addLine(to: CGPoint(x: (cx - 58)*s, y: (cy - 10)*s))
                p.addLine(to: CGPoint(x: (cx - 18)*s, y: (cy - 302)*s))
                p.addLine(to: CGPoint(x: cx*s, y: (cy - 302)*s))
                p.closeSubpath()
            }, with: .color(Color.white.opacity(0.14)))

            // Güney (mat lacivert) yarısı
            let needleS = Path { p in
                p.move(to: CGPoint(x: cx*s, y: cy*s))
                p.addLine(to: CGPoint(x: (cx - 48)*s, y: (cy + 8)*s))
                p.addLine(to: CGPoint(x: cx*s, y: (cy + 248)*s))
                p.addLine(to: CGPoint(x: (cx + 48)*s, y: (cy + 8)*s))
                p.closeSubpath()
            }
            ctx.fill(needleS, with: .linearGradient(
                Gradient(stops: [
                    .init(color: Color(red:0.12,green:0.22,blue:0.38), location: 0.0),
                    .init(color: Color(red:0.08,green:0.14,blue:0.26), location: 1.0)
                ]),
                startPoint: CGPoint(x: cx*s, y: cy*s),
                endPoint: CGPoint(x: cx*s, y: (cy + 248)*s)
            ))

            // Güney kenar şeridi
            ctx.stroke(needleS,
                       with: .color(Color(red:0.28,green:0.42,blue:0.62).opacity(0.5)),
                       lineWidth: 1.2 * s)

            // ─── 7. MERKEZ HALKALAR ─────────────────────────────────
            // Dış halka dolgu
            ctx.fill(
                Path(ellipseIn: CGRect(
                    x: center.x - innerR, y: center.y - innerR,
                    width: innerR*2, height: innerR*2)),
                with: .color(navy0)
            )
            // Altın halka çember
            ctx.stroke(
                Path(ellipseIn: CGRect(
                    x: center.x - innerR, y: center.y - innerR,
                    width: innerR*2, height: innerR*2)),
                with: .linearGradient(
                    Gradient(colors: [gold0, gold2, gold4]),
                    startPoint: CGPoint(x: center.x - innerR, y: center.y - innerR),
                    endPoint: CGPoint(x: center.x + innerR, y: center.y + innerR)
                ),
                lineWidth: 4.5 * s
            )
            // İç dolgu daire
            let dotR: CGFloat = 26 * s
            ctx.fill(
                Path(ellipseIn: CGRect(
                    x: center.x - dotR, y: center.y - dotR,
                    width: dotR*2, height: dotR*2)),
                with: .linearGradient(
                    Gradient(colors: [gold0, gold2]),
                    startPoint: CGPoint(x: center.x - dotR, y: center.y - dotR),
                    endPoint: CGPoint(x: center.x + dotR, y: center.y + dotR)
                )
            )
            // Merkez parlak nokta
            let dotCore: CGFloat = 10 * s
            ctx.fill(
                Path(ellipseIn: CGRect(
                    x: center.x - dotCore, y: center.y - dotCore,
                    width: dotCore*2, height: dotCore*2)),
                with: .color(Color.white.opacity(0.92))
            )

            // ─── 8. BASAMAK GRAFİĞİ (sol alt) ──────────────────────
            let stepW: CGFloat  = 72  * s
            let baseY: CGFloat  = 880 * s
            let steps: [(x: CGFloat, h: CGFloat, opacity: Double)] = [
                (130, 110, 0.28),
                (218, 195, 0.48),
                (306, 290, 0.68),
                (394, 400, 0.88),
            ]
            let rx = 14 * s

            for step in steps {
                let rect = CGRect(
                    x: step.x * s,
                    y: baseY - step.h * s,
                    width: stepW,
                    height: step.h * s
                )
                ctx.fill(
                    Path(roundedRect: rect, cornerRadius: rx),
                    with: .linearGradient(
                        Gradient(stops: [
                            .init(color: gold0.opacity(step.opacity), location: 0.0),
                            .init(color: gold4.opacity(step.opacity * 0.6), location: 1.0)
                        ]),
                        startPoint: CGPoint(x: rect.midX, y: rect.minY),
                        endPoint: CGPoint(x: rect.midX, y: rect.maxY)
                    )
                )
                // Bar sol parlaklık şeridi
                let shineRect = CGRect(
                    x: step.x * s + 6*s,
                    y: baseY - step.h * s + 8*s,
                    width: 12*s,
                    height: step.h * s - 16*s
                )
                ctx.fill(
                    Path(roundedRect: shineRect, cornerRadius: 6*s),
                    with: .color(Color.white.opacity(step.opacity * 0.18))
                )
            }

            // Basamakları birleştiren yükselen çizgi
            var trendLine = Path()
            trendLine.move(to: CGPoint(x: (130 + 36)*s, y: (880 - 110)*s))
            trendLine.addLine(to: CGPoint(x: (218 + 36)*s, y: (880 - 195)*s))
            trendLine.addLine(to: CGPoint(x: (306 + 36)*s, y: (880 - 290)*s))
            trendLine.addLine(to: CGPoint(x: (394 + 36)*s, y: (880 - 400)*s))
            // Ok ucu
            trendLine.addLine(to: CGPoint(x: (394 + 36 - 36)*s, y: (880 - 400 - 52)*s))
            trendLine.move(to: CGPoint(x: (394 + 36)*s, y: (880 - 400)*s))
            trendLine.addLine(to: CGPoint(x: (394 + 36 + 36)*s, y: (880 - 400 - 52)*s))

            ctx.stroke(trendLine,
                       with: .linearGradient(
                        Gradient(colors: [gold1.opacity(0.5), gold0.opacity(0.85)]),
                        startPoint: CGPoint(x: 166*s, y: 770*s),
                        endPoint: CGPoint(x: 430*s, y: 480*s)
                       ),
                       style: StrokeStyle(lineWidth: 5*s, lineCap: .round, lineJoin: .round))

            // ─── 9. KENAR ÇERÇEVESİ ────────────────────────────────
            ctx.stroke(
                bgPath,
                with: .linearGradient(
                    Gradient(colors: [gold1.opacity(0.28), gold3.opacity(0.08)]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: size, y: size)
                ),
                lineWidth: 2.5 * s
            )
        }
    }

    // MARK: - Kuzey yıldızı çizici
    private func drawStar(ctx: GraphicsContext, cx: CGFloat, cy: CGFloat,
                          r: CGFloat, s: CGFloat, color: Color) {
        var path = Path()
        let points = 4
        for i in 0..<(points * 2) {
            let angle = CGFloat(i) * .pi / CGFloat(points) - .pi / 2
            let radius = i.isMultiple(of: 2) ? r : r * 0.38
            let pt = CGPoint(
                x: cx + radius * cos(angle),
                y: cy + radius * sin(angle)
            )
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()
        ctx.fill(path, with: .color(color.opacity(0.92)))
    }
}

// MARK: - Preview
#Preview("1024px") {
    ZStack {
        Color(white: 0.12)
        AppIconView()
            .frame(width: 512, height: 512)
            .clipShape(RoundedRectangle(cornerRadius: 113, style: .continuous))
            .shadow(color: .black.opacity(0.5), radius: 40, y: 16)
    }
    .frame(width: 640, height: 640)
}

#Preview("Boyut Skalası") {
    ZStack {
        Color(white: 0.10)
        HStack(spacing: 24) {
            ForEach([180, 120, 76, 60, 40], id: \.self) { px in
                VStack(spacing: 8) {
                    AppIconView()
                        .frame(width: CGFloat(px), height: CGFloat(px))
                        .clipShape(RoundedRectangle(
                            cornerRadius: CGFloat(px) * 0.22,
                            style: .continuous))
                        .shadow(color: .black.opacity(0.4), radius: 8, y: 3)
                    Text("\(px)px")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
        }
        .padding(30)
    }
    .frame(width: 680, height: 280)
}

#Preview("Açık Arka Plan") {
    ZStack {
        Color(white: 0.92)
        AppIconView()
            .frame(width: 200, height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 44, style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 20, y: 8)
    }
    .frame(width: 320, height: 320)
}
