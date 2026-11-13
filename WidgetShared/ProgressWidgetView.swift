import SwiftUI
import WidgetKit

struct ProgressWidgetView: View {
    let entry: ProgressEntry
    @Environment(\.widgetFamily) private var family
    private var snapshot: WidgetSnapshot { entry.snapshot }
    private var accent: Color { Color(red: WidgetIdentity.accent[0], green: WidgetIdentity.accent[1], blue: WidgetIdentity.accent[2]) }
    private var background: Color { Color(red: WidgetIdentity.background[0], green: WidgetIdentity.background[1], blue: WidgetIdentity.background[2]) }
    private var medium: Bool { family == .systemMedium }
    var body: some View {
        VStack(alignment: .leading, spacing: medium ? 9 : 6) {
            HStack(spacing: 5) {
                Image(systemName: WidgetIdentity.icon).foregroundStyle(accent).widgetAccentable()
                Text(WidgetIdentity.displayName.uppercased()).tracking(1).lineLimit(1).minimumScaleFactor(0.7)
                Spacer(minLength: 0)
                if medium { Image(systemName: "arrow.up.right").foregroundStyle(accent) }
            }.font(.system(size: 10, weight: .bold, design: .rounded))
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(snapshot.title).font(.system(size: medium ? 15 : 12, weight: .semibold, design: WidgetIdentity.serif ? .serif : .rounded)).lineLimit(2).minimumScaleFactor(0.8)
                    Text(snapshot.value).font(.system(size: medium ? 32 : 27, weight: .bold, design: WidgetIdentity.serif ? .serif : .rounded)).foregroundStyle(accent).lineLimit(1).minimumScaleFactor(0.55).monospacedDigit().widgetAccentable()
                    Text(snapshot.label).font(.system(size: 11, weight: .medium)).lineLimit(2).minimumScaleFactor(0.8)
                }.frame(maxWidth: .infinity, alignment: .leading)
                if medium && !snapshot.isEmpty {
                    artwork.frame(width: 125, height: 76).accessibilityHidden(true)
                }
            }
            if !medium && !snapshot.isEmpty {
                ProgressView(value: snapshot.progress).tint(accent).accessibilityLabel("Progress").accessibilityValue("\(Int(snapshot.progress * 100)) percent")
            }
            Spacer(minLength: 0)
            Text(medium ? snapshot.detail : snapshot.footnote)
                .font(.system(size: 10, weight: .medium)).foregroundStyle(.white.opacity(0.78)).lineLimit(2).minimumScaleFactor(0.8)
            if medium { Text(snapshot.footnote).font(.system(size: 9)).foregroundStyle(.white.opacity(0.6)).lineLimit(1) }
        }
        .foregroundStyle(.white)
        .containerBackground(for: .widget) {
            LinearGradient(colors: [background, background.opacity(0.92), accent.opacity(0.22)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        .widgetURL(WidgetIdentity.url)
    }
    @ViewBuilder private var artwork: some View {
        switch WidgetIdentity.theme {
        case "candles":
            SwiftUI.Canvas { context, size in
                let bars = snapshot.candles
                let low = bars.map(\.low).min() ?? 0, high = bars.map(\.high).max() ?? 1
                let span = max(0.0001, high - low)
                let step = size.width / CGFloat(max(1,bars.count))
                func y(_ value: Double) -> CGFloat { size.height * CGFloat(1 - (value - low) / span) }
                for (i,c) in bars.enumerated() {
                    let x = CGFloat(i) * step + step / 2
                    let colour: Color = c.close >= c.open ? accent : .pink
                    var wick = Path(); wick.move(to: CGPoint(x:x,y:y(c.high))); wick.addLine(to: CGPoint(x:x,y:y(c.low)))
                    context.stroke(wick, with: .color(colour), lineWidth: 1)
                    let rect = CGRect(x: x-step*0.27, y:min(y(c.open),y(c.close)), width:step*0.54,height:max(2,abs(y(c.open)-y(c.close))))
                    context.fill(Path(roundedRect:rect,cornerRadius:1),with:.color(colour))
                }
            }
        case "tower":
            VStack(spacing: 3) {
                ForEach(0..<8) { i in
                    RoundedRectangle(cornerRadius: 2).fill(accent.opacity(0.4 + Double(i)*0.07))
                        .frame(width: CGFloat(42+i*9),height:6).offset(x: CGFloat(i%2)*4)
                }
            }.rotationEffect(.degrees(-5))
        case "reels", "vault":
            VStack(spacing: 12) {
                HStack(spacing: 6) {
                    ForEach(Array(snapshot.symbols.prefix(3).enumerated()),id:\.offset) { _, symbol in
                        Group {
                            if symbol.hasPrefix("emoji:") { Text(String(symbol.dropFirst(6))) }
                            else { Image(systemName: symbol) }
                        }.font(.system(size:25,weight:.semibold)).foregroundStyle(accent)
                            .frame(width:36,height:46).background(accent.opacity(0.10),in:RoundedRectangle(cornerRadius:8))
                    }
                }
                ProgressView(value: snapshot.progress).tint(accent)
            }
        case "football":
            VStack(spacing: 8) {
                Image(systemName: "soccerball").font(.system(size: 38)).foregroundStyle(accent)
                HStack(spacing: 3) { ForEach(0..<5) { i in RoundedRectangle(cornerRadius:2).fill(Double(i)/5 < snapshot.progress ? accent : accent.opacity(0.18)).frame(height:7) } }
            }
        case "notebook":
            VStack(spacing: 9) {
                ForEach(Array(snapshot.values.prefix(3).enumerated()),id:\.offset) { _,value in
                    GeometryReader { geo in
                        ZStack(alignment:.leading) {
                            Capsule().fill(accent.opacity(0.15))
                            Capsule().fill(accent).frame(width:geo.size.width*CGFloat(max(0.02,min(1,value))))
                        }
                    }.frame(height:12)
                }
            }
        default:
            ZStack {
                Circle().stroke(accent.opacity(0.18),lineWidth:10)
                Circle().trim(from:0,to:snapshot.progress).stroke(accent,style:StrokeStyle(lineWidth:10,lineCap:.round)).rotationEffect(.degrees(-90))
                Image(systemName:WidgetIdentity.icon).font(.system(size:24)).foregroundStyle(accent)
            }.padding(5)
        }
    }
}
