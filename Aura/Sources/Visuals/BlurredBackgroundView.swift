//
//  BlurredBackgroundView.swift
//  Aura
//

import SwiftUI
import UIKit

/// The soft, overscanned image layer behind Aura's liquid-glass interface.
/// Pass `nil` while the user has not selected a photo; the fallback still gives
/// cards a colourful surface to refract.
struct BlurredBackgroundView: View {
    let image: UIImage?
    var blurRadius: CGFloat = 48

    var body: some View {
        GeometryReader { proxy in
            Group {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    fallbackGradient
                }
            }
            // Overscan hides transparent edges produced by the blur and shader.
            .frame(width: proxy.size.width, height: proxy.size.height)
            .scaleEffect(1.16)
            .blur(radius: max(40, blurRadius), opaque: true)
            .saturation(1.18)
            .overlay(Color.black.opacity(0.08))
            .clipped()
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private var fallbackGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.11, green: 0.05, blue: 0.26),
                Color(red: 0.02, green: 0.34, blue: 0.46),
                Color(red: 0.31, green: 0.09, blue: 0.42)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

#Preview {
    BlurredBackgroundView(image: nil)
}
