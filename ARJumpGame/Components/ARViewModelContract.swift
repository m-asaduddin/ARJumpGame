//
//  ARViewContaine.swift
//  AruNanda
//
//  Created by Asad on 13/11/25.
//
import RealityKit
import ARKit

protocol ARViewModelPotocol: AnyObject {
    
    func getARView() -> ARView
//    func getScore() -> Int
    func addEntityModel(models: ModelEntity...)
}

protocol ARViewSessionDelegate: AnyObject {
    func whenHeadTouchBox()
    func whenHeadTouchObstacle()
}

protocol ARViewSession: ARSessionDelegate, AnyObject {
    var arView: ARView? { get set }
    func getConfig() -> ARConfiguration
}
