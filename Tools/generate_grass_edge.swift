import AppKit

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let output = root.appendingPathComponent("Resources/Backgrounds/grass-edge-tile.png")
guard !FileManager.default.fileExists(atPath: output.path) else { fatalError("Already exists; refusing overwrite") }
let size = 256
let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: size * 4,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
context.setFillColor(CGColor(red: 0x9B/255.0, green: 0xD4/255.0, blue: 0xB8/255.0, alpha: 1))
context.fill(CGRect(x: 0, y: 0, width: size, height: size))
context.setStrokeColor(CGColor(red: 0x5F/255.0, green: 0xB9/255.0, blue: 0x8F/255.0, alpha: 0.4))
context.setLineWidth(1)
for row in 0..<8 {
    for col in 0..<8 {
        let x = CGFloat(col * 32 + (row % 2) * 8 + 8), y = CGFloat(row * 32 + 12)
        context.move(to: CGPoint(x: x-3, y: y+5)); context.addLine(to: CGPoint(x: x, y: y))
        context.addLine(to: CGPoint(x: x+3, y: y+4)); context.strokePath()
    }
}
let data = NSBitmapImageRep(cgImage: context.makeImage()!).representation(using: .png, properties: [:])!
try data.write(to: output)
let imageSet = root.appendingPathComponent("Resources/Assets.xcassets/GrassEdgeTile.imageset")
try FileManager.default.createDirectory(at: imageSet, withIntermediateDirectories: true)
try data.write(to: imageSet.appendingPathComponent("grass-edge-tile.png"))
try JSONSerialization.data(withJSONObject: ["info": ["author":"xcode", "version":1], "images": [["idiom":"universal", "filename":"grass-edge-tile.png", "scale":"1x"]]], options: [.prettyPrinted]).write(to: imageSet.appendingPathComponent("Contents.json"))
print(output.path)
