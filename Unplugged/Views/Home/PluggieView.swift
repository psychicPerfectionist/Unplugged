import SwiftUI

struct PluggieView: View {
    @EnvironmentObject private var pluggieVM: PluggieViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var bodyOffset: CGFloat = 0
    @State private var bodyRotation: Double = 0
    @State private var flashOpacity: Double = 0
    @State private var sparkleVisible: Bool = false

    private var mood: PluggieMood { pluggieVM.mood }

    var body: some View {
        ZStack {
            // Sparkles behind the body (thriving only)
            if mood == .thriving {
                SparkleRing(visible: sparkleVisible)
            }

            // Shadow
            Ellipse()
                .fill(.black.opacity(0.07))
                .frame(width: 120, height: 20)
                .offset(y: 90 + bodyOffset * 0.3)
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: bodyOffset)

            // Body
            ZStack {
                pluggieBody
                pluggieDecals
            }
            .offset(y: bodyOffset)
            .rotationEffect(.degrees(bodyRotation))

            // Critical flash overlay
            Circle()
                .fill(Color.red.opacity(flashOpacity))
                .frame(width: 140, height: 140)
                .allowsHitTesting(false)
        }
        .frame(width: 200, height: 200)
        .onAppear  { applyAnimations() }
        .onChange(of: mood) { applyAnimations() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Pluggie, \(mood.accessibilityLabel)")
        .accessibilityValue("\(Int(100 - pluggieVM.healthPercent)) percent health remaining")
    }

    // MARK: - Body shape

    private var pluggieBody: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [mood.tintColor.opacity(0.9), mood.tintColor],
                    center: .topLeading,
                    startRadius: 10,
                    endRadius: 80
                )
            )
            .frame(width: 130, height: 130)
            .shadow(color: mood.tintColor.opacity(0.35), radius: 16, y: 8)
            .animation(.easeInOut(duration: 1.0), value: mood)
    }

    // MARK: - Decals (eyes + extras)

    @ViewBuilder
    private var pluggieDecals: some View {
        switch mood {
        case .thriving:
            HappyEyes()
        case .content:
            ContentEyes()
        case .worried:
            WorriedEyes()
        case .struggling:
            StrugglingEyes()
        case .critical:
            CriticalEyes()
        case .dead:
            DeadEyes()
        }
    }

    // MARK: - Animations

    private func applyAnimations() {
        // Reset all
        bodyOffset   = 0
        bodyRotation = 0
        flashOpacity = 0
        sparkleVisible = false

        guard !reduceMotion else { return }

        switch mood {
        case .thriving:
            sparkleVisible = true
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                bodyOffset = -14
            }

        case .content:
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                bodyOffset = -5
            }

        case .worried:
            withAnimation(.easeInOut(duration: 0.25).repeatForever(autoreverses: true)) {
                bodyRotation = 2
            }

        case .struggling:
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                bodyOffset = -3
            }

        case .critical:
            withAnimation(.easeInOut(duration: 0.12).repeatForever(autoreverses: true)) {
                flashOpacity = 0.18
            }

        case .dead:
            withAnimation(.easeIn(duration: 0.4)) {
                bodyOffset = 8
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Eye Variants
// ─────────────────────────────────────────────────────────────────────────────

private struct HappyEyes: View {
    var body: some View {
        HStack(spacing: 22) {
            // Happy arc eyes (^‿^)
            Arc()
                .stroke(.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 16, height: 10)
            Arc()
                .stroke(.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 16, height: 10)
        }
        .offset(y: -8)
    }
}

private struct Arc: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addArc(
            center: CGPoint(x: rect.midX, y: rect.maxY),
            radius: rect.width / 2,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: true
        )
        return p
    }
}

private struct ContentEyes: View {
    var body: some View {
        HStack(spacing: 22) {
            eyeDot
            eyeDot
        }
        .offset(y: -8)
    }

    private var eyeDot: some View {
        Capsule()
            .fill(.white)
            .frame(width: 10, height: 14)
    }
}

private struct WorriedEyes: View {
    var body: some View {
        ZStack {
            HStack(spacing: 20) {
                eyeDot
                eyeDot
            }
            .offset(y: -10)

            // Sweat drop
            SweatDrop()
                .offset(x: 30, y: -2)
        }
    }

    private var eyeDot: some View {
        Capsule()
            .fill(.white)
            .frame(width: 10, height: 14)
            .overlay(
                Capsule()
                    .fill(.black.opacity(0.6))
                    .frame(width: 6, height: 8)
                    .offset(y: 2)
            )
    }
}

private struct SweatDrop: View {
    var body: some View {
        Teardrop()
            .fill(Color(hex: "#81D4FA").opacity(0.85))
            .frame(width: 10, height: 14)
            .rotationEffect(.degrees(180))
    }
}

private struct Teardrop: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY),
            control1: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.3),
            control2: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        p.addCurve(
            to: CGPoint(x: rect.midX, y: rect.minY),
            control1: CGPoint(x: rect.minX, y: rect.maxY),
            control2: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.3)
        )
        return p
    }
}

private struct StrugglingEyes: View {
    var body: some View {
        HStack(spacing: 20) {
            tireddEye(flipX: false)
            tireddEye(flipX: true)
        }
        .offset(y: -10)
    }

    private func tireddEye(flipX: Bool) -> some View {
        ZStack {
            Capsule()
                .fill(.white)
                .frame(width: 12, height: 16)
            // Heavy eyelid
            Rectangle()
                .fill(Color(hex: "#FF9800").opacity(0.6))
                .frame(width: 12, height: 8)
                .offset(y: -4)
                .clipShape(Capsule())
        }
        .scaleEffect(x: flipX ? -1 : 1)
    }
}

private struct CriticalEyes: View {
    @State private var spin = false

    var body: some View {
        HStack(spacing: 22) {
            spiralEye
            spiralEye
        }
        .offset(y: -8)
        .onAppear { withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) { spin = true } }
    }

    private var spiralEye: some View {
        Text("@")
            .font(.system(size: 18, weight: .black))
            .foregroundStyle(.white)
            .rotationEffect(.degrees(spin ? 360 : 0))
    }
}

private struct DeadEyes: View {
    var body: some View {
        HStack(spacing: 22) {
            xEye
            xEye
        }
        .offset(y: -8)
    }

    private var xEye: some View {
        ZStack {
            Rectangle()
                .fill(.white)
                .frame(width: 16, height: 3)
                .rotationEffect(.degrees(45))
            Rectangle()
                .fill(.white)
                .frame(width: 16, height: 3)
                .rotationEffect(.degrees(-45))
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Sparkle Ring
// ─────────────────────────────────────────────────────────────────────────────

private struct SparkleRing: View {
    let visible: Bool
    @State private var rotate: Double = 0

    var body: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { i in
                Sparkle()
                    .offset(x: 0, y: -82)
                    .rotationEffect(.degrees(Double(i) * 60 + rotate))
                    .opacity(visible ? 1 : 0)
                    .animation(
                        .easeInOut(duration: 0.8).delay(Double(i) * 0.1),
                        value: visible
                    )
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                rotate = 360
            }
        }
    }
}

private struct Sparkle: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color(hex: "#FDD835"))
                .frame(width: 2, height: 10)
            Rectangle()
                .fill(Color(hex: "#FDD835"))
                .frame(width: 10, height: 2)
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Preview
// ─────────────────────────────────────────────────────────────────────────────

#Preview("All moods") {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 24) {
            ForEach([0, 800, 1900, 2800, 3300, 3600], id: \.self) { usage in
                VStack(spacing: 8) {
                    let vm = PluggieViewModel(
                        service: MockScreenTimeService(
                            startUsageSeconds: usage, limitSeconds: 3600, ticksPerSecond: 0
                        )
                    )
                    PluggieView()
                        .frame(width: 180, height: 180)
                        .environmentObject(vm)
                    Text(vm.mood.accessibilityLabel)
                        .font(.caption.bold())
                }
            }
        }
        .padding()
    }
}
