import SwiftUI

enum Ink {
    static let background = Color(hex: 0x0B1220)
    static let panel = Color(hex: 0x162238)
    static let gold = Color(hex: 0xF5BE4F)
    static let green = Color(hex: 0x43D9A3)
    static let red = Color(hex: 0xFF6B70)
    static let text = Color(hex: 0xF5F7FC)
    static let muted = Color(hex: 0xA4B1C7)
    static let skins = [gold, green, Color(hex: 0x7CCDF5), Color(hex: 0xB59BFF)]
    static let locations = ["Night City", "Dune Valley", "Frozen Cliffs", "Orbital Station"]
    static let symbols = ["building.2", "sun.haze", "mountain.2", "sparkles"]
    static let skinNames = ["Gilded", "Jade", "Glacier", "Aurora"]
    static let skinRules = ["Your first building material", "Make 30 perfect placements in total", "Reach 10 floors in one attempt", "Make 15 perfect placements in a row"]
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 255) / 255, green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255)
    }
}

struct GoldButton: View {
    var title: String
    var icon = "arrow.up"
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) { Text(title); Image(systemName: icon).font(.headline) }
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Ink.background)
                .frame(maxWidth: .infinity, minHeight: 58)
                .background(LinearGradient(colors: [Color(hex: 0xFFDA81), Ink.gold], startPoint: .top, endPoint: .bottom), in: RoundedRectangle(cornerRadius: 18))
                .overlay(alignment: .top) { Capsule().fill(.white.opacity(0.5)).frame(height: 1).padding(.horizontal, 20) }
                .shadow(color: Ink.gold.opacity(0.16), radius: 16, y: 6)
        }.buttonStyle(.plain)
    }
}

struct QuietButton: View {
    var title: String
    var icon: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon).font(.system(size: 15, weight: .semibold))
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Ink.panel, in: RoundedRectangle(cornerRadius: 14))
        }.buttonStyle(.plain)
    }
}

struct Metric: View {
    var value: String
    var label: String
    var accent: Color = Ink.text
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 30, weight: .bold, design: .rounded)).monospacedDigit().foregroundStyle(accent)
            Text(label).font(.system(size: 12, weight: .medium)).foregroundStyle(Ink.muted)
        }.frame(maxWidth: .infinity).accessibilityElement(children: .combine)
    }
}

struct PageHeading: View {
    var eyebrow: String
    var title: String
    var subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(eyebrow.uppercased()).font(.system(size: 12, weight: .bold)).tracking(2).foregroundStyle(Ink.gold)
            Text(title).font(.system(size: 34, weight: .bold, design: .rounded))
            Text(subtitle).font(.system(size: 15)).foregroundStyle(Ink.muted)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension View {
    func panel() -> some View { padding(16).background(Ink.panel, in: RoundedRectangle(cornerRadius: 20)) }
}

struct WorldBackdrop: View {
    var location: Int = 0
    var body: some View {
        Canvas { context, size in
            let tint: Color = [Color(hex: 0x23446A), Color(hex: 0x66452F), Color(hex: 0x25596C), Color(hex: 0x3B3268)][location]
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(Gradient(colors: [tint.opacity(0.5), Ink.background]), startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
            for i in 0..<36 {
                let x = Double((i * 73 + 19) % 331) / 331 * size.width
                let y = Double((i * 43 + 7) % 223) / 320 * size.height
                let r = i % 5 == 0 ? 1.7 : 0.8
                context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r * 2, height: r * 2)), with: .color(.white.opacity(0.12 + Double(i % 3) * 0.1)))
            }
            for layer in 0..<3 {
                let base = size.height * (0.72 + Double(layer) * 0.1)
                if location == 0 {
                    for i in 0..<13 {
                        let w = size.width / 10
                        let h = CGFloat((i * 37 + layer * 29) % 90 + 28)
                        let x = CGFloat(i) * w - w
                        context.fill(Path(CGRect(x: x, y: base - h, width: w - 4, height: size.height - base + h)), with: .color(tint.opacity(0.18 + Double(layer) * 0.1)))
                        for window in 0..<3 where i % 2 == 0 {
                            context.fill(Path(CGRect(x: x + 9, y: base - h + 12 + CGFloat(window) * 17, width: 3, height: 5)), with: .color(Ink.gold.opacity(0.16)))
                        }
                    }
                } else if location == 3 {
                    let rect = CGRect(x: -size.width * 0.4, y: base, width: size.width * 1.8, height: size.height * 0.65)
                    context.stroke(Path(ellipseIn: rect), with: .color(tint.opacity(0.6)), lineWidth: CGFloat(2 + layer * 6))
                } else {
                    var path = Path(); path.move(to: CGPoint(x: 0, y: size.height))
                    for i in 0...8 {
                        path.addLine(to: CGPoint(x: CGFloat(i) * size.width / 8, y: base - CGFloat((i * 31 + layer * 23) % 95)))
                    }
                    path.addLine(to: CGPoint(x: size.width, y: size.height)); path.closeSubpath()
                    context.fill(path, with: .color(tint.opacity(0.2 + Double(layer) * 0.14)))
                }
            }
        }.accessibilityHidden(true)
    }
}

struct TowerScene: View, Animatable {
    var platforms: [Platform]
    var movingX: Double? = nil
    var skin: Int = 0
    var location: Int = 0
    var fullTower = false
    var rotation: Double = 0
    nonisolated var cameraFloor: Double = 0
    nonisolated var animatableData: Double {
        get { cameraFloor }
        set { cameraFloor = newValue }
    }
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                WorldBackdrop(location: location)
                Circle().fill(Ink.skins[skin].opacity(0.06)).frame(width: geometry.size.width * 0.8).blur(radius: 30).offset(y: -50)
                Canvas { context, size in
                    let scale = min(size.width / 410, 1.6)
                    let available = size.height - 100
                    let step = fullTower ? min(28 * scale, available / CGFloat(max(8, platforms.count + 1))) : 28 * scale
                    let visible = Int(max(4, available / step))
                    let camera = fullTower ? 0 : max(0, cameraFloor + 1 - Double(visible))
                    let baseline = size.height - 55 + CGFloat(camera) * step
                    let shift = (size.width - 320 * scale) / 2 - 14 * scale
                    for p in platforms where fullTower || Double(p.id) >= camera - 2 {
                        drawBlock(context: &context, x: p.x * scale + shift, y: baseline - CGFloat(p.id) * step,
                                  width: p.width * scale, scale: scale, colour: Ink.skins[skin], perfect: p.perfect)
                    }
                    if let movingX, let last = platforms.last {
                        let y = baseline - CGFloat(platforms.count) * step - 12
                        var guide = Path(); guide.move(to: CGPoint(x: 12, y: y + 20)); guide.addLine(to: CGPoint(x: size.width - 12, y: y + 20))
                        context.stroke(guide, with: .color(.white.opacity(0.13)), style: StrokeStyle(lineWidth: 1, dash: [3, 5]))
                        drawBlock(context: &context, x: movingX * scale + shift, y: y, width: last.width * scale,
                                  scale: scale, colour: Ink.skins[skin], perfect: true)
                    }
                    let label = Text("T O W E R   R U S H").font(.system(size: 10, weight: .medium)).foregroundColor(Ink.muted.opacity(0.5))
                    context.draw(label, at: CGPoint(x: size.width / 2, y: size.height - 15))
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0))
        .accessibilityLabel("Tower with \(max(0, platforms.count - 1)) floors")
    }

    private func drawBlock(context: inout GraphicsContext, x: Double, y: Double, width: Double, scale: Double, colour: Color, perfect: Bool) {
        let d = 28 * scale, skew = 32 * scale, h = 16 * scale
        let left = x - width / 2, right = x + width / 2
        func polygon(_ points: [CGPoint]) -> Path {
            var p = Path(); p.addLines(points); p.closeSubpath(); return p
        }
        let top = polygon([.init(x: left, y: y), .init(x: right, y: y), .init(x: right + skew, y: y - d), .init(x: left + skew, y: y - d)])
        let face = polygon([.init(x: left, y: y), .init(x: right, y: y), .init(x: right, y: y + h), .init(x: left, y: y + h)])
        let side = polygon([.init(x: right, y: y), .init(x: right + skew, y: y - d), .init(x: right + skew, y: y - d + h), .init(x: right, y: y + h)])
        context.fill(face, with: .color(Ink.background))
        context.fill(face, with: .linearGradient(Gradient(colors: [colour.opacity(0.85), colour.opacity(0.48)]), startPoint: .init(x: left, y: y), endPoint: .init(x: right, y: y + h)))
        context.fill(side, with: .color(Ink.background))
        context.fill(side, with: .color(colour.opacity(0.38)))
        context.fill(top, with: .color(Ink.background))
        context.fill(top, with: .linearGradient(Gradient(colors: [colour, colour.opacity(0.75)]), startPoint: .init(x: left, y: y - d), endPoint: .init(x: right, y: y)))
        context.stroke(top, with: .color(.white.opacity(perfect ? 0.7 : 0.26)), lineWidth: perfect ? 1.2 : 0.5)
        var edge = Path(); edge.move(to: .init(x: left + 3, y: y + 3)); edge.addLine(to: .init(x: right - 3, y: y + 3))
        context.stroke(edge, with: .color(.white.opacity(0.15)), lineWidth: 1)
    }

    static let illustration: [Platform] = (0..<9).map { Platform(id: $0, x: 160 + Double($0 % 3) * 3, width: 180 - Double($0) * 7, perfect: $0 % 3 == 0) }
}
