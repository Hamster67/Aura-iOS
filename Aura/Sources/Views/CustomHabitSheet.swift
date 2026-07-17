import SwiftUI
import SwiftData

/// The creation sheet is deliberately self-contained: it owns temporary UI state
/// and commits exactly one SwiftData model only when the user taps Create.
struct CustomHabitSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var title = ""
    @State private var selectedColor = "47D7FF"
    @State private var selectedIcon: LiquidIconKind = .water
    @State private var target = 1.0
    private let palette = ["47D7FF", "A88BFF", "FF6FAE", "FFB75D", "65F2B5"]

    var body: some View {
        NavigationStack {
            ZStack {
                BlurredBackgroundView(image: nil).opacity(0.94)
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 26) {
                        Text("Create a ritual").font(.system(size: 34, weight: .bold, design: .rounded))
                        TextField("What will you make space for?", text: $title)
                            .textInputAutocapitalization(.sentences)
                            .padding(17).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

                        sectionTitle("Liquid colour")
                        HStack(spacing: 15) {
                            ForEach(palette, id: \.self) { hex in
                                FluidColorOrb(hex: hex, isSelected: selectedColor == hex) {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) { selectedColor = hex }
                                }
                            }
                        }

                        sectionTitle("Ritual glyph")
                        HStack(spacing: 16) {
                            ForEach(LiquidIconKind.allCases) { kind in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.68)) { selectedIcon = kind }
                                } label: {
                                    LiquidIconPainter(kind: kind, color: Color(auraHex: selectedColor))
                                        .frame(width: 47, height: 47)
                                        .padding(9)
                                        .background(selectedIcon == kind ? Color(auraHex: selectedColor).opacity(0.22) : .white.opacity(0.07), in: Circle())
                                }.buttonStyle(.plain)
                            }
                        }

                        sectionTitle("Daily intention · \(Int(target))")
                        FluidSlider(value: $target, range: 1...20, tint: Color(auraHex: selectedColor))
                            .frame(height: 54)
                    }
                    .padding(24)
                    .foregroundStyle(.white)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel", action: dismiss.callAsFunction) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create", action: create)
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.clear)
    }

    private func sectionTitle(_ value: String) -> some View { Text(value).font(.headline.weight(.semibold)) }
    private func create() {
        modelContext.insert(HabitModel(title: title.trimmingCharacters(in: .whitespacesAndNewlines), colorHex: selectedColor, iconName: selectedIcon.systemFallback))
        dismiss()
    }
}

private struct FluidColorOrb: View {
    let hex: String
    let isSelected: Bool
    let select: () -> Void
    @State private var isPressed = false
    private var color: Color { Color(auraHex: hex) }

    var body: some View {
        Button(action: select) {
            Circle()
                .fill(RadialGradient(colors: [.white.opacity(0.9), color, color.opacity(0.45)], center: .topLeading, startRadius: 1, endRadius: 24))
                .frame(width: 42, height: 42)
                .overlay(Circle().stroke(.white.opacity(isSelected ? 0.9 : 0.28), lineWidth: isSelected ? 2.5 : 1))
                .scaleEffect(isPressed ? 0.8 : (isSelected ? 1.13 : 1))
                .shadow(color: color.opacity(0.8), radius: isSelected ? 14 : 5)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(DragGesture(minimumDistance: 0).onChanged { _ in isPressed = true }.onEnded { _ in withAnimation(.spring(response: 0.38, dampingFraction: 0.42)) { isPressed = false } })
    }
}

/// Thumb scale and trailing capsule respond separately, creating a small water-drop inertia illusion.
private struct FluidSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let tint: Color
    @State private var dragging = false
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            let width = max(1, proxy.size.width - 30)
            let fraction = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
            let x = CGFloat(fraction) * width + 15
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.12)).frame(height: 10)
                Capsule().fill(LinearGradient(colors: [tint.opacity(0.45), tint, .white], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(10, x), height: 10).shadow(color: tint, radius: 7)
                Capsule().fill(tint.opacity(0.55)).frame(width: dragging ? 42 + abs(dragOffset) * 0.12 : 20, height: 12).offset(x: min(max(0, x - 10), width - 10) - (dragging && dragOffset < 0 ? 20 : 0)).blur(radius: 2)
                Circle().fill(RadialGradient(colors: [.white, tint], center: .topLeading, startRadius: 1, endRadius: 15)).frame(width: 30, height: 30).scaleEffect(dragging ? 1.14 : 1).offset(x: x - 15).shadow(color: tint, radius: 9)
            }
            .frame(height: proxy.size.height)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { gesture in
                dragging = true; dragOffset = gesture.translation.width
                let f = min(1, max(0, gesture.location.x / width))
                value = (range.lowerBound + f * (range.upperBound - range.lowerBound)).rounded()
            }.onEnded { _ in withAnimation(.spring(response: 0.45, dampingFraction: 0.58)) { dragging = false; dragOffset = 0 } })
        }
    }
}
