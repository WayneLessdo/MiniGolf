import AppKit

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let assets = root.appendingPathComponent("Resources/Assets.xcassets")
let exports = root.appendingPathComponent("Resources/Exports")
let fm = FileManager.default
func writeJSON(_ value: Any, _ url: URL) throws {
    try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    guard !fm.fileExists(atPath: url.path) else { return }
    try JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted, .sortedKeys]).write(to: url)
}
func color(_ hex: String) -> NSColor {
    let n = UInt32(hex, radix: 16)!
    return NSColor(srgbRed: CGFloat((n>>16)&255)/255, green: CGFloat((n>>8)&255)/255, blue: CGFloat(n&255)/255, alpha: 1)
}
let colors: [String:(String,String)] = [
    "Grass":("9BD4B8","9BD4B8"), "GrassDeep":("5FB98F","5FB98F"),
    "Sand":("FBF7F0","FBF7F0"), "RewardGold":("E8B96A","E8B96A"),
    "PenaltyRed":("E06B5C","E06B5C"), "Water":("6FB4D6","6FB4D6"),
    "Surface":("FBF7F0","101218"), "TextPrimary":("26362D","FBF7F0"),
    "TextSecondary":("26362D","9BD4B8"), "TextLight":("FBF7F0","FBF7F0"),
    "TextDark":("26362D","26362D")
]
let info: [String:Any] = ["author":"xcode","version":1]
try writeJSON(["info":info], assets.appendingPathComponent("Contents.json"))
for (name,pair) in colors {
    func entry(_ hex: String, dark: Bool) -> [String:Any] {
        let c = color(hex)
        var v: [String:Any] = ["idiom":"universal", "color":["color-space":"srgb", "components":["red":String(format:"%.6f",c.redComponent),"green":String(format:"%.6f",c.greenComponent),"blue":String(format:"%.6f",c.blueComponent),"alpha":"1.000"]]]
        if dark { v["appearances"] = [["appearance":"luminosity","value":"dark"]] }
        return v
    }
    try writeJSON(["info":info,"colors":[entry(pair.0,dark:false),entry(pair.1,dark:true)]],assets.appendingPathComponent("\(name).colorset/Contents.json"))
}

func ellipse(_ r: CGRect, _ c: NSColor) { c.setFill(); NSBezierPath(ovalIn:r).fill() }
func stroke(_ points:[CGPoint], _ c:NSColor, _ width:CGFloat, close:Bool=false, fill:Bool=false) {
    let p=NSBezierPath(); p.move(to:points[0]); points.dropFirst().forEach { p.line(to:$0) }
    if close { p.close() }; p.lineWidth=width; p.lineCapStyle = .round; p.lineJoinStyle = .round
    c.set(); if fill { p.fill() } else { p.stroke() }
}
func star(_ center:CGPoint, _ radius:CGFloat, _ c:NSColor) {
    let pts=(0..<10).map { i -> CGPoint in
        let a=CGFloat(i) * .pi / 5 + .pi/2; let r=radius*(i%2 == 0 ? 1:0.46)
        return CGPoint(x:center.x+cos(a)*r,y:center.y+sin(a)*r)
    }; stroke(pts,c,0,close:true,fill:true)
}
func draw(_ name:String) {
    let ink=color("26362D"), mint=color("9BD4B8"), gold=color("E8B96A")
    switch name {
    case "GolfBall":
        ellipse(CGRect(x:18,y:13,width:70,height:70),ink.withAlphaComponent(0.14))
        ellipse(CGRect(x:15,y:19,width:70,height:70),color("FBF7F0"))
        for row in 0..<6 { for col in 0..<6 {
            let x=CGFloat(col)*10+25, y=CGFloat(row)*10+28
            if hypot(x-50,y-54)<26 { ellipse(CGRect(x:x,y:y,width:3,height:3),ink.withAlphaComponent(0.09)) }
        }}
    case "Flag":
        ellipse(CGRect(x:22,y:9,width:55,height:12),ink.withAlphaComponent(0.2))
        stroke([CGPoint(x:45,y:16),CGPoint(x:45,y:92)],color("FBF7F0"),4)
        stroke([CGPoint(x:47,y:91),CGPoint(x:84,y:77),CGPoint(x:47,y:63)],color("E06B5C"),0,close:true,fill:true)
    case "Cup": ellipse(CGRect(x:10,y:22,width:80,height:56),mint); ellipse(CGRect(x:20,y:27,width:60,height:44),ink)
    case "SandEdge":
        let p=NSBezierPath(roundedRect:CGRect(x:7,y:23,width:86,height:52),xRadius:26,yRadius:26)
        color("E8B96A").withAlphaComponent(0.6).setFill();p.fill()
        let p2=NSBezierPath(roundedRect:CGRect(x:10,y:28,width:80,height:49),xRadius:24,yRadius:24)
        color("FBF7F0").setFill();p2.fill()
    case "PowerRing":
        let p=NSBezierPath(ovalIn:CGRect(x:12,y:12,width:76,height:76));p.lineWidth=6;mint.setStroke();p.stroke()
        ellipse(CGRect(x:39,y:39,width:22,height:22),ink)
    case "DirectionArrow": stroke([CGPoint(x:50,y:12),CGPoint(x:50,y:88),CGPoint(x:29,y:65)],ink,7);stroke([CGPoint(x:50,y:88),CGPoint(x:71,y:65)],ink,7)
    case "Star":star(CGPoint(x:50,y:50),43,gold)
    case "SpeedLine":
        for i in 0..<3 { let y=CGFloat(i)*20+27;stroke([CGPoint(x:12+CGFloat(i)*8,y:y),CGPoint(x:86,y:y+10)],gold,5) }
    case "PenaltyBorder":
        let p=NSBezierPath(roundedRect:CGRect(x:7,y:7,width:86,height:86),xRadius:18,yRadius:18);p.lineWidth=4;color("E06B5C").setStroke();p.stroke()
    case "CanalTile":
        color("6FB4D6").setFill();NSBezierPath(rect:CGRect(x:0,y:0,width:100,height:100)).fill()
        for row in 0..<5 {
            let pts=(0...100).map { x in CGPoint(x:CGFloat(x),y:CGFloat(row)*20+10+sin(CGFloat(x)*2 * .pi/100)*2) }
            stroke(pts,color("FBF7F0").withAlphaComponent(0.18),1)
        }
    case "AppIcon":
        color("FBF7F0").setFill();NSBezierPath(rect:CGRect(x:0,y:0,width:100,height:100)).fill()
        let p=NSBezierPath(roundedRect:CGRect(x:4,y:10,width:92,height:60),xRadius:28,yRadius:28);mint.setFill();p.fill()
        stroke([CGPoint(x:16,y:28),CGPoint(x:38,y:37),CGPoint(x:56,y:54)],gold,5)
        ellipse(CGRect(x:52,y:32,width:33,height:33),ink.withAlphaComponent(0.15))
        ellipse(CGRect(x:49,y:38,width:33,height:33),color("FBF7F0"))
        stroke([CGPoint(x:77,y:67),CGPoint(x:77,y:92)],ink,2)
        stroke([CGPoint(x:78,y:92),CGPoint(x:94,y:85),CGPoint(x:78,y:78)],color("E06B5C"),0,close:true,fill:true)
    default: break
    }
}
func png(_ name:String, size:Int, transparent:Bool, url:URL) throws {
    guard !fm.fileExists(atPath:url.path) else { return }
    let alpha: CGImageAlphaInfo = transparent ? .premultipliedLast : .noneSkipLast
    let c=CGContext(data:nil,width:size,height:size,bitsPerComponent:8,bytesPerRow:size*4,space:CGColorSpace(name:CGColorSpace.sRGB)!,bitmapInfo:alpha.rawValue)!
    NSGraphicsContext.saveGraphicsState();NSGraphicsContext.current=NSGraphicsContext(cgContext:c,flipped:false)
    c.scaleBy(x:CGFloat(size)/100,y:CGFloat(size)/100)
    draw(name);NSGraphicsContext.restoreGraphicsState()
    let rep=NSBitmapImageRep(cgImage:c.makeImage()!)
    try rep.representation(using:.png,properties:[:])!.write(to:url)
}
let shapes=["GolfBall","Flag","Cup","SandEdge","PowerRing","DirectionArrow","Star","SpeedLine","PenaltyBorder"]
for name in shapes {
    let folder=assets.appendingPathComponent("\(name).imageset")
    try fm.createDirectory(at:folder,withIntermediateDirectories:true)
    let url=folder.appendingPathComponent("\(name).pdf")
    if fm.fileExists(atPath: url.path) { continue }
    var box=CGRect(x:0,y:0,width:100,height:100)
    let ctx=CGContext(url as CFURL,mediaBox:&box,nil)!
    ctx.beginPDFPage(nil)
    NSGraphicsContext.saveGraphicsState();NSGraphicsContext.current=NSGraphicsContext(cgContext:ctx,flipped:false)
    draw(name);NSGraphicsContext.restoreGraphicsState();ctx.endPDFPage();ctx.closePDF()
    try writeJSON(["info":info,"images":[["idiom":"universal","filename":"\(name).pdf"]],"properties":["preserves-vector-representation":true,"template-rendering-intent":name == "DirectionArrow" || name == "Star" || name == "SpeedLine" ? "template":"original"]],folder.appendingPathComponent("Contents.json"))
}
try png("GolfBall",size:1024,transparent:true,url:exports.appendingPathComponent("golf-ball-1024.png"))
try png("Flag",size:1024,transparent:true,url:exports.appendingPathComponent("flag-1024.png"))
try png("Star",size:1024,transparent:true,url:exports.appendingPathComponent("star-1024.png"))
try png("CanalTile",size:256,transparent:false,url:root.appendingPathComponent("Resources/Backgrounds/canal-tile.png"))
let tile=assets.appendingPathComponent("CanalTile.imageset")
try fm.createDirectory(at:tile,withIntermediateDirectories:true)
if !fm.fileExists(atPath:tile.appendingPathComponent("canal-tile.png").path) { try fm.copyItem(at:root.appendingPathComponent("Resources/Backgrounds/canal-tile.png"),to:tile.appendingPathComponent("canal-tile.png")) }
try writeJSON(["info":info,"images":[["idiom":"universal","filename":"canal-tile.png","scale":"1x"]]],tile.appendingPathComponent("Contents.json"))
let icon=assets.appendingPathComponent("AppIcon.appiconset")
try fm.createDirectory(at:icon,withIntermediateDirectories:true)
try png("AppIcon",size:1024,transparent:false,url:icon.appendingPathComponent("AppIcon.png"))
try writeJSON(["info":info,"images":[["idiom":"universal","platform":"ios","size":"1024x1024","filename":"AppIcon.png"]]],icon.appendingPathComponent("Contents.json"))
print("Generated 11 adaptive color sets, 9 vector image sets, tile, 2 transparent exports, and opaque AppIcon.")
