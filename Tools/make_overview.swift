import AppKit
let root=URL(fileURLWithPath:FileManager.default.currentDirectoryPath)
let w=1800,h=1050
let context=CGContext(data:nil,width:w,height:h,bitsPerComponent:8,bytesPerRow:w*4,space:CGColorSpace(name:CGColorSpace.sRGB)!,bitmapInfo:CGImageAlphaInfo.noneSkipLast.rawValue)!
NSGraphicsContext.saveGraphicsState();NSGraphicsContext.current=NSGraphicsContext(cgContext:context,flipped:false)
NSColor(calibratedRed:0.97,green:0.96,blue:0.93,alpha:1).setFill();NSBezierPath(rect:NSRect(x:0,y:0,width:w,height:h)).fill()
let items=[("duo-compact-delivery.png","COMPACT / OUTER"),("duo-regular.png","REGULAR / OPEN"),("duo-folded.png","FOLDED / DIVISION")]
for (i,item) in items.enumerated() {
    let image=NSImage(contentsOf:root.appendingPathComponent("docs/screenshots/"+item.0))!
    let box=CGRect(x:CGFloat(i)*600+28,y:60,width:544,height:890)
    let ratio=min(box.width/image.size.width,box.height/image.size.height)
    let size=CGSize(width:image.size.width*ratio,height:image.size.height*ratio)
    image.draw(in:CGRect(x:box.midX-size.width/2,y:box.midY-size.height/2,width:size.width,height:size.height))
    (item.1 as NSString).draw(at:CGPoint(x:CGFloat(i)*600+28,y:980),withAttributes:[.font:NSFont.systemFont(ofSize:19,weight:.semibold),.foregroundColor:NSColor(calibratedRed:0.15,green:0.21,blue:0.18,alpha:1)])
}
NSGraphicsContext.restoreGraphicsState()
let output=root.appendingPathComponent("docs/screenshots/overview-delivery.png")
precondition(!FileManager.default.fileExists(atPath:output.path),"Refusing overwrite")
try NSBitmapImageRep(cgImage:context.makeImage()!).representation(using:.png,properties:[:])!.write(to:output)
print(output.path)
