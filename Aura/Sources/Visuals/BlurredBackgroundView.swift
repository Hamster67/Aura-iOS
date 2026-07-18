import SwiftUI
import UIKit

/// The soft, overscanned image layer behind Aura's liquid-glass interface.
struct BlurredBackgroundView: View {
    let image: UIImage?
    var blurRadius: CGFloat = 48

    var body: some View {
        GeometryReader { proxy in
            Group {
                // 優先使用動態傳入或已儲存的自訂背景，最後才使用極簡漸層 fallback
                if let displayImage = resolveImage() {
                    Image(uiImage: displayImage)
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
            .overlay(Color.black.opacity(0.12)) // 微調調暗，確保自訂照片背景的易讀性
            .clipped()
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    /// 判斷當前渲染的圖片來源
    private func resolveImage() -> UIImage? {
        if let image { return image }
        if let data = SharedContainer.customBackgroundData {
            return UIImage(data: data)
        }
        return nil
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