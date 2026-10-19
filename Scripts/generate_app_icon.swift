import AppKit
import CoreGraphics
import ImageIO

let size = 1024
let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: size * 4, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
    fatalError("Could not create icon canvas")
}

let bounds = CGRect(x: 0, y: 0, width: size, height: size)
let backgroundColors = [
    CGColor(red: 0.018, green: 0.035, blue: 0.050, alpha: 1),
    CGColor(red: 0.025, green: 0.105, blue: 0.125, alpha: 1),
    CGColor(red: 0.055, green: 0.080, blue: 0.135, alpha: 1)
] as CFArray
let background = CGGradient(colorsSpace: colorSpace, colors: backgroundColors, locations: [0, 0.58, 1])!
context.drawLinearGradient(background, start: CGPoint(x: 80, y: 80), end: CGPoint(x: 940, y: 950), options: [])

let glowColors = [
    CGColor(red: 0.20, green: 0.96, blue: 0.78, alpha: 0.25),
    CGColor(red: 0.20, green: 0.96, blue: 0.78, alpha: 0)
] as CFArray
let glow = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: [0, 1])!
context.drawRadialGradient(glow, startCenter: CGPoint(x: 720, y: 740), startRadius: 8, endCenter: CGPoint(x: 720, y: 740), endRadius: 560, options: [])

let center = CGPoint(x: 512, y: 512)
for radius in [376.0, 326.0, 276.0, 226.0] {
    context.setStrokeColor(CGColor(red: 0.62, green: 0.97, blue: 0.87, alpha: 0.12))
    context.setLineWidth(2)
    context.strokeEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
}

let heights: [CGFloat] = [144, 240, 320, 430, 320, 240, 144]
let barWidth: CGFloat = 48
let gap: CGFloat = 32
let totalWidth = CGFloat(heights.count) * barWidth + CGFloat(heights.count - 1) * gap
let firstX = (CGFloat(size) - totalWidth) / 2
let mint = CGColor(red: 0.50, green: 0.96, blue: 0.82, alpha: 1)
context.saveGState()
context.setShadow(offset: .zero, blur: 30, color: CGColor(red: 0.28, green: 0.96, blue: 0.78, alpha: 0.50))
context.setFillColor(mint)
for (index, height) in heights.enumerated() {
    let x = firstX + CGFloat(index) * (barWidth + gap)
    let rect = CGRect(x: x, y: center.y - height / 2, width: barWidth, height: height)
    let path = CGPath(roundedRect: rect, cornerWidth: barWidth / 2, cornerHeight: barWidth / 2, transform: nil)
    context.addPath(path)
    context.fillPath()
}
context.restoreGState()

guard let image = context.makeImage() else { fatalError("Could not render icon") }
let output = URL(fileURLWithPath: "Sources/Rhythm/Assets.xcassets/AppIcon.appiconset/AppIcon.png") as CFURL
guard let destination = CGImageDestinationCreateWithURL(output, "public.png" as CFString, 1, nil) else {
    fatalError("Could not create PNG output")
}
CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else {
    fatalError("Could not save app icon")
}
print("Generated Rhythm waveform icon (1024x1024)")
