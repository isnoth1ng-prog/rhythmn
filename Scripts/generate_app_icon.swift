import AppKit
import CoreGraphics
import ImageIO

let size = 1024
let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: size * 4, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
    fatalError("Could not create icon canvas")
}
let bounds = CGRect(x: 0, y: 0, width: size, height: size)
let colors = [
    CGColor(red: 0.015, green: 0.035, blue: 0.055, alpha: 1),
    CGColor(red: 0.035, green: 0.12, blue: 0.17, alpha: 1),
    CGColor(red: 0.07, green: 0.22, blue: 0.23, alpha: 1)
] as CFArray
let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 0.58, 1])!
context.drawLinearGradient(gradient, start: CGPoint(x: 120, y: 100), end: CGPoint(x: 910, y: 930), options: [])
context.saveGState()
let tile = CGRect(x: 156, y: 156, width: 712, height: 712)
context.addPath(CGPath(roundedRect: tile, cornerWidth: 190, cornerHeight: 190, transform: nil))
context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.035))
context.fillPath()
context.setStrokeColor(CGColor(red: 0.55, green: 1, blue: 0.86, alpha: 0.35))
context.setLineWidth(3)
context.addPath(CGPath(roundedRect: tile, cornerWidth: 190, cornerHeight: 190, transform: nil))
context.strokePath()
context.setStrokeColor(CGColor(red: 0.42, green: 1, blue: 0.82, alpha: 1))
context.setLineWidth(34)
context.strokeEllipse(in: CGRect(x: 310, y: 310, width: 404, height: 404))
context.setStrokeColor(CGColor(red: 0.72, green: 1, blue: 0.9, alpha: 0.5))
context.setLineWidth(9)
context.strokeEllipse(in: CGRect(x: 382, y: 382, width: 260, height: 260))
let play = CGMutablePath()
play.move(to: CGPoint(x: 474, y: 615))
play.addLine(to: CGPoint(x: 620, y: 512))
play.addLine(to: CGPoint(x: 474, y: 409))
play.closeSubpath()
context.addPath(play)
context.setFillColor(CGColor(red: 0.58, green: 1, blue: 0.86, alpha: 1))
context.fillPath()
context.restoreGState()
guard let image = context.makeImage() else { fatalError("Could not render icon") }
let output = URL(fileURLWithPath: "Sources/Rhythm/Assets.xcassets/AppIcon.appiconset/AppIcon.png") as CFURL
guard let destination = CGImageDestinationCreateWithURL(output, "public.png" as CFString, 1, nil) else {
    fatalError("Could not create PNG output")
}
CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else { fatalError("Could not save app icon") }
print("Generated Rhythm app icon (1024x1024)")
