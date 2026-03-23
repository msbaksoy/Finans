// CircularPhotoCropView.swift — Tek adımda yuvarlak kırpma (önizleme = çıktı)
import SwiftUI
import UIKit

struct CircularPhotoCropView: View {
    let sourceImage: UIImage
    var onSave: (UIImage) -> Void
    var onCancel: (() -> Void)? = nil

    @State private var offset = CGSize.zero
    @State private var lastOffset = CGSize.zero
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    /// GeometryReader ölçüleri — export ile birebir aynı hesap için saklanır
    @State private var layoutCW: CGFloat = 0
    @State private var layoutCH: CGFloat = 0
    @State private var layoutCircleD: CGFloat = 0

    @Environment(\.dismiss) private var dismiss

    private var frameW: CGFloat {
        guard layoutCircleD > 0, layoutCW > 0, layoutCH > 0 else { return 300 }
        return max(layoutCircleD, layoutCW) * scale
    }

    private var frameH: CGFloat {
        guard layoutCircleD > 0, layoutCW > 0, layoutCH > 0 else { return 300 }
        return max(layoutCircleD, layoutCH) * scale
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let circleD = min(geo.size.width, geo.size.height) - 60

                ZStack {
                    Color.black.ignoresSafeArea()

                    Image(uiImage: sourceImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: max(circleD, geo.size.width) * scale,
                               height: max(circleD, geo.size.height) * scale)
                        .offset(x: offset.width, y: offset.height)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in lastOffset = offset }
                        )
                        .simultaneousGesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let newScale = lastScale * value
                                    scale = max(0.5, min(newScale, 4.0))
                                }
                                .onEnded { _ in lastScale = scale }
                        )

                    Canvas { ctx, size in
                        ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black.opacity(0.6)))
                        let circleRect = CGRect(
                            x: (size.width - circleD) / 2,
                            y: (size.height - circleD) / 2,
                            width: circleD,
                            height: circleD
                        )
                        ctx.blendMode = .destinationOut
                        ctx.fill(Path(ellipseIn: circleRect), with: .color(.white))
                    }
                    .compositingGroup()
                    .allowsHitTesting(false)

                    Circle()
                        .stroke(Color.white.opacity(0.8), lineWidth: 2)
                        .frame(width: circleD, height: circleD)
                        .allowsHitTesting(false)

                    VStack {
                        Spacer()
                        Text("Sürükleyin ve yakınlaştırın — tek adımda kaydedilir")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 16)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .onAppear {
                    layoutCW = geo.size.width
                    layoutCH = geo.size.height
                    layoutCircleD = circleD
                }
                .onChange(of: geo.size) { _, new in
                    layoutCW = new.width
                    layoutCH = new.height
                    layoutCircleD = min(new.width, new.height) - 60
                }
            }
            .navigationTitle("Profil Fotoğrafı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.black.opacity(0.85), for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") {
                        onCancel?()
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        if let cropped = renderCroppedExport() {
                            onSave(cropped)
                        }
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "3B82F6"))
                }
            }
        }
    }

    /// Önizleme ile aynı düzeni SwiftUI’de çizer, daireyi kare içine alıp yüksek çözünürlükte JPEG için ölçekler.
    private func renderCroppedExport() -> UIImage? {
        guard layoutCW > 1, layoutCH > 1, layoutCircleD > 1 else { return nil }
        guard #available(iOS 16.0, *) else { return legacyCropFallback() }

        let cw = layoutCW
        let ch = layoutCH
        let circleD = layoutCircleD
        let fw = max(circleD, cw) * scale
        let fh = max(circleD, ch) * scale

        let exportContent = ZStack {
            Color.white
            Image(uiImage: sourceImage)
                .resizable()
                .scaledToFill()
                .frame(width: fw, height: fh)
                .offset(x: offset.width, y: offset.height)
        }
        .frame(width: cw, height: ch)
        .mask(
            Circle()
                .frame(width: circleD, height: circleD)
        )
        .drawingGroup()

        let renderer = ImageRenderer(content: exportContent)
        renderer.scale = UIScreen.main.scale
        renderer.isOpaque = true
        guard let full = renderer.uiImage,
              let cgFull = full.cgImage else { return legacyCropFallback() }

        let scalePx = CGFloat(cgFull.width) / cw
        let cropSide = circleD * scalePx
        let originX = (CGFloat(cgFull.width) - cropSide) / 2
        let originY = (CGFloat(cgFull.height) - cropSide) / 2
        let cropRect = CGRect(x: originX, y: originY, width: cropSide, height: cropSide)

        guard let croppedCg = cgFull.cropping(to: cropRect) else { return legacyCropFallback() }
        let square = UIImage(cgImage: croppedCg, scale: full.scale, orientation: full.imageOrientation)

        return resizeImage(square, maxSide: 900)
    }

    /// Eski sürümler / ImageRenderer başarısızsa basit ölçekli dairesel kırpma
    private func legacyCropFallback() -> UIImage? {
        let out: CGFloat = 800
        guard let cg = sourceImage.cgImage else { return nil }
        let iw = CGFloat(cg.width)
        let ih = CGFloat(cg.height)
        guard iw > 0, ih > 0 else { return nil }

        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = true
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: out, height: out), format: format)
        return renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: out, height: out))
            let path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: out, height: out))
            path.addClip()
            let s = max(out / iw, out / ih) * scale
            let drawW = iw * s
            let drawH = ih * s
            let ox = (out - drawW) / 2 + offset.width * (out / max(layoutCW, 1))
            let oy = (out - drawH) / 2 + offset.height * (out / max(layoutCH, 1))
            UIImage(cgImage: cg, scale: sourceImage.scale, orientation: sourceImage.imageOrientation)
                .draw(in: CGRect(x: ox, y: oy, width: drawW, height: drawH))
        }
    }

    private func resizeImage(_ image: UIImage, maxSide: CGFloat) -> UIImage {
        let w = image.size.width
        let h = image.size.height
        let m = max(w, h)
        guard m > maxSide, m > 0 else { return image }
        let r = maxSide / m
        let nw = w * r
        let nh = h * r
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = image.scale
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: nw, height: nh), format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(x: 0, y: 0, width: nw, height: nh))
        }
    }
}
