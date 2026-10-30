// Regenerate from the repository root: swift tools/render-app-icons.swift
// Original vector artwork; shared geometry for iPhone and Mac.
import AppKit

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let ios = root.appendingPathComponent("apps/ios/sonytvremote/Assets.xcassets/AppIcon.appiconset")
let mac = root.appendingPathComponent("apps/macos/Assets.xcassets/AppIcon.appiconset")
func gray(_ value: CGFloat, _ alpha: CGFloat = 1) -> NSColor { NSColor(white: value, alpha: alpha) }
func rounded(_ rect: NSRect, _ radius: CGFloat, _ color: NSColor) {
    color.setFill(); NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
}
func circle(_ x: CGFloat, _ y: CGFloat, _ radius: CGFloat, _ color: NSColor) {
    color.setFill(); NSBezierPath(ovalIn: NSRect(x: x-radius, y: y-radius, width: radius*2, height: radius*2)).fill()
}
func line(_ points: [NSPoint], _ color: NSColor, width: CGFloat) {
    let path = NSBezierPath(); path.lineWidth = width; path.lineCapStyle = .round; path.lineJoinStyle = .round
    path.move(to: points[0]); for point in points.dropFirst() { path.line(to: point) }
    color.setStroke(); path.stroke()
}
func render(size: Int, style: String, isMac: Bool, url: URL) throws {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
                              bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                              isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let transform = AffineTransform(scale: CGFloat(size)/1024)
    (transform as NSAffineTransform).concat()
    let dark = style != "light"
    let bounds = isMac ? NSRect(x: 40, y: 40, width: 944, height: 944) : NSRect(x: 0, y: 0, width: 1024, height: 1024)
    let background = NSBezierPath(roundedRect: bounds, xRadius: isMac ? 210 : 0, yRadius: isMac ? 210 : 0)
    let top = dark ? NSColor(srgbRed: 0.19, green: 0.22, blue: 0.26, alpha: 1) : NSColor(srgbRed: 0.94, green: 0.96, blue: 0.98, alpha: 1)
    let bottom = dark ? NSColor(srgbRed: 0.035, green: 0.045, blue: 0.06, alpha: 1) : NSColor(srgbRed: 0.77, green: 0.81, blue: 0.86, alpha: 1)
    NSGradient(starting: style == "tinted" ? gray(0.14) : top, ending: style == "tinted" ? gray(0.02) : bottom)!.draw(in: background, angle: 270)
    let body = NSBezierPath(roundedRect: NSRect(x: 320, y: 112, width: 384, height: 800), xRadius: 112, yRadius: 112)
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow(); shadow.shadowColor = gray(0, dark ? 0.55 : 0.26); shadow.shadowBlurRadius = 32; shadow.shadowOffset = NSSize(width: 0, height: -14); shadow.set()
    gray(dark ? 0.85 : 0.14).setFill(); body.fill()
    NSGraphicsContext.restoreGraphicsState()
    NSGradient(starting: gray(dark ? 0.94 : 0.25), ending: gray(dark ? 0.68 : 0.075))!.draw(in: body, angle: 270)
    body.lineWidth = 3; gray(1, dark ? 0.7 : 0.45).setStroke(); body.stroke()
    // The circular directional pad matches the actual remote UI.
    circle(512, 674, 146, gray(dark ? 0.17 : 0.09))
    let pad = NSBezierPath(ovalIn: NSRect(x: 368, y: 530, width: 288, height: 288))
    NSGradient(starting: gray(0.30), ending: gray(0.12))!.draw(in: pad, angle: 270)
    circle(512, 674, 65, gray(0.48))
    for (x,y) in [(512.0,782.0),(620,674),(512,566),(404,674)] { circle(x,y,5,gray(0.87)) }
    let key = gray(dark ? 0.22 : 0.32)
    let ink = gray(0.97)
    circle(444, 438, 37, key)
    line([NSPoint(x:449,y:450),NSPoint(x:437,y:438),NSPoint(x:449,y:426)],ink,width:6)
    circle(580, 438, 37, key)
    let screen = NSBezierPath(roundedRect:NSRect(x:561,y:426,width:38,height:26),xRadius:4,yRadius:4)
    screen.lineWidth=5;ink.setStroke();screen.stroke()
    line([NSPoint(x:573,y:418),NSPoint(x:587,y:418)],ink,width:4)
    circle(444, 270, 37, key)
    // Pause/play glyph.
    let triangle=NSBezierPath();triangle.move(to:NSPoint(x:430,y:284));triangle.line(to:NSPoint(x:430,y:256));triangle.line(to:NSPoint(x:449,y:270));triangle.close();ink.setFill();triangle.fill()
    rounded(NSRect(x:455,y:256,width:5,height:28),2,ink)
    rounded(NSRect(x:544,y:194,width:72,height:148),36,key)
    line([NSPoint(x:565,y:304),NSPoint(x:595,y:304)],ink,width:5)
    line([NSPoint(x:580,y:289),NSPoint(x:580,y:319)],ink,width:5)
    line([NSPoint(x:565,y:232),NSPoint(x:595,y:232)],ink,width:5)
    NSGraphicsContext.restoreGraphicsState()
    let output: NSBitmapImageRep
    if isMac { output = rep }
    else {
        // Render through an opaque RGB context: iOS primary icons must have no alpha channel.
        let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
                                bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
        context.draw(rep.cgImage!, in: CGRect(x: 0, y: 0, width: size, height: size))
        output = NSBitmapImageRep(cgImage: context.makeImage()!)
    }
    try output.representation(using: .png, properties: [:])!.write(to: url)
}
for style in ["light", "dark", "tinted"] {
    try render(size:1024,style:style,isMac:false,url:ios.appendingPathComponent("AppIcon-\(style).png"))
}
for points in [16,32,128,256,512] {
    for scale in [1,2] {
        let suffix = scale == 2 ? "@2x" : ""
        try render(size:points*scale,style:"light",isMac:true,url:mac.appendingPathComponent("icon_\(points)x\(points)\(suffix).png"))
    }
}
