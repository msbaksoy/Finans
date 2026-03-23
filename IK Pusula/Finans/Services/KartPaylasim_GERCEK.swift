// ================================================================
// KartPaylasim_GERCEK.swift
// Yalnızca UIImage paylaşır — metin yok (WhatsApp/iMessage görsel).
// ================================================================

import SwiftUI
import UIKit

/// Yalnızca görsel paylaşır. Metin içermez.
struct GoselPaylasSheet: UIViewControllerRepresentable {
    let gorsel: UIImage
    var tamamlandi: (() -> Void)? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(
            activityItems: [gorsel],
            applicationActivities: nil
        )
        if let popover = vc.popoverPresentationController {
            popover.sourceView = UIView()
            popover.sourceRect = CGRect(
                x: UIScreen.main.bounds.midX,
                y: UIScreen.main.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }
        vc.completionWithItemsHandler = { _, _, _, _ in
            tamamlandi?()
        }
        return vc
    }

    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
