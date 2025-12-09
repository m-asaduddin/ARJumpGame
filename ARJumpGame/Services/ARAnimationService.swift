//
//  ARAnimationService.swift
//  AruNanda
//
//  Created by Asad on 15/11/25.
//
import RealityKit

// animations for AR
final class ARAnimationService {
    static func objectHitAnimation(model: Entity, targetScale: SIMD3<Float>) -> AnimationResource {
        let originalTransform: Transform = model.transform
        var firstStep: Transform = model.transform
        var secondStep: Transform = model.transform
        
        firstStep.scale = [ARAnimationService.checkScale(targetScale.x),
                           ARAnimationService.checkScale(targetScale.y),
                           ARAnimationService.checkScale(targetScale.z)]
        secondStep.scale = targetScale
        
        let firstAnimation = FromToByAnimation(from: originalTransform, to: firstStep, duration: 0.25)
        let secondAnimation = FromToByAnimation(from: firstStep, to: secondStep, duration: 0.1)
        let thirdAnimation = FromToByAnimation(from: secondStep, to: originalTransform, duration: 0.45)
        
        let firstAnimationResource = try! AnimationResource.generate(with: AnimationView(source: firstAnimation, bindTarget: .transform, delay: 0.05))
        let secondAnimatioResource = try! AnimationResource.generate(with: AnimationView(source: secondAnimation, bindTarget: .transform, delay: 0.01))
        let thirdAnimatioResource = try! AnimationResource.generate(with: AnimationView(source: thirdAnimation, bindTarget: .transform, delay: 0.02))
        
        return try! AnimationResource.sequence(with: [firstAnimationResource, secondAnimatioResource, thirdAnimatioResource])
    }
    
    static func checkScale(_ scale: Float) -> Float{
        let offset = abs(1 - scale)
        if scale > 1 {
            return 0.8 - offset
        } else if scale < 1 {
            return 1.2 + offset
        } else {
            return 1
        }
    }
}
