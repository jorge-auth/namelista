import SwiftUI

struct WheelView: View {
    let items: [String]

    var colors: [Color] = [
        .orange, .blue, .green, .purple, .pink, .teal, .indigo, .yellow, .mint, .cyan
    ]

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                ForEach(items.indices, id: \.self) { i in
                    let anglePerSlice = 360.0 / Double(max(items.count, 1))
                    let start = Angle(degrees: Double(i) * anglePerSlice - 90)
                    let end = Angle(degrees: Double(i + 1) * anglePerSlice - 90)
                    SliceShape(startAngle: start, endAngle: end)
                        .fill(colors[i % colors.count].opacity(0.85))
                }

                // Labels centered along each slice's mid-arc, oriented from arc -> center
                ForEach(items.indices, id: \.self) { i in
                    let anglePerSlice = 360.0 / Double(max(items.count, 1))
                    let midAngle = Angle(degrees: (Double(i) + 0.5) * anglePerSlice - 90)
                    let radius = size / 2
                    let labelRadius = radius * 0.6

                    Text(items[i])
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.black.opacity(0.25))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        // Rotate so baseline points inward toward center
                        .rotationEffect(midAngle + Angle(degrees: 180))
                        .fixedSize()
                        .offset(x: cos(midAngle.radians) * labelRadius,
                                y: sin(midAngle.radians) * labelRadius)
                }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.primary.opacity(0.2), lineWidth: 2))
            .shadow(radius: 3)
        }
    }
}

struct SliceShape: Shape {
    var startAngle: Angle
    var endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        path.move(to: center)
        path.addArc(center: center,
                    radius: radius,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: false)
        path.closeSubpath()
        return path
    }
}

struct WheelView_Previews: PreviewProvider {
    static var previews: some View {
        WheelView(items: ["Alice", "Bob", "Carol", "Dave"]) 
            .frame(width: 280, height: 280)
            .padding()
    }
}


