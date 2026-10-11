import Foundation
import CoreGraphics

struct FPTuning: Codable {
    struct Input: Codable {
        let deadZone: Double
        let maximumDrag: Double
        let availableFraction: Double
        let exponent: Double
        let lowBand: Double
        let highBand: Double
        func maximum(in size: CGSize) -> CGFloat {
            min(maximumDrag,max(deadZone+12,min(size.width,size.height)*availableFraction))
        }
    }
    struct Material: Codable { let drag: Double; let restitution: Double }
    struct Physics: Codable {
        let maximumSpeed: Double
        let grass: Material
        let sand: Material
        let bank: Material
        let wallRestitution: Double
        let stopSpeed: Double
        let settleDuration: Double
        let bankMargin: Double
        let captureRadius: Double
        let captureEdgeSpeed: Double
        let captureCenterSpeed: Double
        func captureLimit(distance: CGFloat) -> CGFloat {
            guard distance <= captureRadius else { return 0 }
            let near = 1-min(1,max(0,distance/captureRadius))
            return captureEdgeSpeed+(captureCenterSpeed-captureEdgeSpeed)*near
        }
    }
    struct Boost: Codable {
        let requiredStars: Int
        let duration: Double
        let predictionSeconds: Double
        let predictionStep: Double
    }
    let variant: String
    let compact: Input
    let regular: Input
    let physics: Physics
    let boost: Boost

    func validate() throws {
        let inputs=[compact,regular]
        let materials=[physics.grass,physics.sand,physics.bank]
        guard !variant.isEmpty,
              inputs.allSatisfy({ [$0.deadZone,$0.maximumDrag,$0.availableFraction,$0.exponent,$0.lowBand,$0.highBand].allSatisfy(\.isFinite) && $0.deadZone>=0 && $0.maximumDrag>$0.deadZone+12 && (0.2...0.8).contains($0.availableFraction) && (1...3).contains($0.exponent) && $0.lowBand>0 && $0.lowBand<$0.highBand && $0.highBand<1 }),
              materials.allSatisfy({ $0.drag.isFinite && $0.drag>0 && $0.restitution.isFinite && (0...1).contains($0.restitution) }),
              [physics.maximumSpeed,physics.stopSpeed,physics.settleDuration,physics.bankMargin,physics.captureRadius,physics.captureEdgeSpeed,physics.captureCenterSpeed,boost.duration,boost.predictionSeconds,boost.predictionStep].allSatisfy({$0.isFinite && $0>0}),
              physics.maximumSpeed<=3,physics.stopSpeed<0.03,physics.settleDuration<=1,
              physics.wallRestitution.isFinite,(0...1).contains(physics.wallRestitution),
              physics.captureRadius>FPLevel.ballRadius,physics.captureRadius<0.2,
              physics.captureCenterSpeed>=physics.captureEdgeSpeed,physics.captureCenterSpeed<physics.maximumSpeed,
              (1...3).contains(boost.requiredStars),boost.duration<=120,
              boost.predictionSeconds<=5,(1.0/120...0.05).contains(boost.predictionStep)
        else { throw NSError(domain:"FoldPutt.Tuning",code:1,userInfo:[NSLocalizedDescriptionKey:"tuning.json 参数非法"] ) }
    }
    static func load(bundle: Bundle = .main) throws -> FPTuning {
        guard let url=bundle.url(forResource:"tuning",withExtension:"json") else { throw NSError(domain:"FoldPutt.Tuning",code:2,userInfo:[NSLocalizedDescriptionKey:"缺少 tuning.json"] ) }
        let tuning=try JSONDecoder().decode(FPTuning.self,from:Data(contentsOf:url))
        try tuning.validate();return tuning
    }
}
