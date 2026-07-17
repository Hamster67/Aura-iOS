//
//  LiquidCanvasView.swift
//  Aura
//

import SwiftUI
import UIKit

/// A reusable full-screen canvas that refracts a blurred user image whenever it
/// is tapped. Foreground content remains undistorted so controls stay legible.
///
/// The canvas intentionally owns only one active ripple. Replacing the event on
/// a new tap avoids accumulating shader work during rapid interaction.
@available(iOS 17.0, *)
struct LiquidCanvasView<Content: View>: View {
    let backgroundImage: UIImage?
    let content: Content

    @State private var ripple = RippleEvent.inactive

    init(
        backgroundImage: UIImage?,
        @ViewBuilder content: () -> Content
    ) {
        self.backgroundImage = backgroundImage
        self.content = content()
    }

    var body: some View {
        GeometryReader { proxy in
            TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !ripple.isActive)) { context in
                let elapsed = ripple.elapsed(at: context.date)

                ZStack {
                    BlurredBackgroundView(image: backgroundImage)
                        .distortionEffect(
                            ShaderLibrary.rippleDistortion(
                                .float(Float(elapsed)),
                                .float2(ripple.location),
                                .float(ripple.strength),
                                .float2(proxy.size)
                            ),
                            // Must cover the shader's maximum sample displacement.
                            maxSampleOffset: CGSize(width: 28, height: 28)
                        )

                    content
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
                .contentShape(Rectangle())
                .simultaneousGesture(
                    SpatialTapGesture()
                        .onEnded { value in
                            beginRipple(at: value.location)
                        }
                )
            }
        }
        .ignoresSafeArea()
    }

    private func beginRipple(at location: CGPoint) {
        // Updating the start date restarts TimelineView without a timer, while
        // its `.animation` schedule supplies display-synchronised frames.
        ripple = RippleEvent(
            location: location,
            startedAt: .now,
            strength: 18
        )
    }
}

@available(iOS 17.0, *)
private struct RippleEvent {
    static let inactive = RippleEvent(location: .zero, startedAt: .distantPast, strength: 0)

    let location: CGPoint
    let startedAt: Date
    let strength: Float

    private let duration: TimeInterval = 1.35

    var isActive: Bool {
        Date.now.timeIntervalSince(startedAt) < duration
    }

    func elapsed(at date: Date) -> TimeInterval {
        min(max(0, date.timeIntervalSince(startedAt)), duration)
    }
}

#Preview("Liquid canvas") {
    LiquidCanvasView(backgroundImage: nil) {
        VStack(spacing: 12) {
            Text("Aura")
                .font(.system(size: 42, weight: .bold, design: .rounded))
            Text("Tap anywhere to release a ripple")
                .font(.callout)
        }
        .foregroundStyle(.white)
        .padding(32)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30))
    }
}
