//
//  ActivityARJumpViewModel.swift
//  ARJumpGame
//
//  Created by Asad on 09/12/25.
//
import RealityKit
import ARKit
internal import Combine

class ActivityARJumpViewModel: NSObject, ObservableObject {
    @Published var score: Int = 0
    var arView: ARView?
    
    private var configuration = ARFaceTrackingConfiguration()
    private var models: [ModelEntity] = []
    private var boxAnchors: [UUID: AnchorEntity] = [:]
    private var headBoxTreshold: Float = 0.01
    private var isTouching: [UUID: Bool] = [:]
    private var fixedY: Float = 0.0
    private var lastValidHeadTop: SIMD3<Float>?
    private var lastUpdateTime: TimeInterval = 0
    var lastHitTime: [UUID: TimeInterval] = [:]
    let hitCooldown: TimeInterval = 0.3 // 300 ms debounce
    
    init(modelsPath: [String]) {
//        super.init()
        for path in modelsPath {
            self.models.append(try! ModelEntity.loadModel(named: path))
        }
        print("supported number of face:",ARFaceTrackingConfiguration.supportedNumberOfTrackedFaces)
        configuration.isWorldTrackingEnabled = true
        configuration.maximumNumberOfTrackedFaces = 2
    }
}

extension ActivityARJumpViewModel: ARViewSession {
    // Dijalankan saat anchor wajah pertama kali terdeteksi
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        let randIndex = Int.random(in: 0...(models.count - 1))
        for (i, faceAnchor) in anchors.enumerated() where faceAnchor is ARFaceAnchor {
            let anchorID = faceAnchor.identifier
            let faceTransform = faceAnchor.transform
            //        let cameraTransform = frame.camera.transform
            //        let worldTransform = simd_mul(simd_inverse(cameraTransform), faceTransform)
            let boxPosition = simd_make_float3(faceTransform.columns.3)
            let faceUp = simd_normalize(simd_make_float3(faceTransform.columns.1))
            // kira-kira 0.12 m (12 cm) dari pusat ke atas
            var headTop = boxPosition + faceUp * 0.12
            print("init: head:", headTop)
            headTop.y = headTop.y + 0.1
//            headTop.z += 0.23
            self.fixedY = headTop.y
            
            print("init: object:", headTop)
            
            // Buat anchor biasa di posisi wajah
            let anchor = AnchorEntity(world: headTop)
            self.boxAnchors[anchorID]  = anchor
            let modelIndex = i == 0 ? randIndex : (randIndex + 1) % models.count
//            print("box anchor: ", self.boxAnchors[anchorID]?.position ?? "not initialized")
            self.boxAnchors[anchorID]?.addChild(models[modelIndex])
//            print("model position",self.boxAnchors[i].position)
            // Tambahkan ke scene
            arView?.scene.addAnchor(self.boxAnchors[anchorID] ?? anchor)
            self.isTouching[anchorID] = false
            print("anchor added!")
        }
    }
    
    // Setiap kali wajah bergerak
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        let timestamp = session.currentFrame?.timestamp ?? 0
        for faceAnchor in anchors where faceAnchor is ARFaceAnchor {
            let faceTransform = faceAnchor.transform
            let anchorID = faceAnchor.identifier
            
            guard let boxAnchor = boxAnchors[anchorID] else { return }
            
            let currentPos = simd_make_float3(faceTransform.columns.3)
            let faceUp = simd_normalize(simd_make_float3(faceTransform.columns.1))
            // kira-kira 0.12 m (12 cm) dari pusat ke atas
            let headTop = currentPos + faceUp * 0.12
            
            let isTrackingFrozen =
                lastValidHeadTop != nil &&
                simd_distance(lastValidHeadTop!, headTop) < 0.005 &&
                timestamp - lastUpdateTime < 0.20

            let actualHeadTop = isTrackingFrozen ? lastValidHeadTop! : headTop

            if !isTrackingFrozen {
                lastValidHeadTop = headTop
                lastUpdateTime = timestamp
            }
            
            let boxContact: Bool = actualHeadTop.y >= self.fixedY
            
            let now = timestamp
            let last = lastHitTime[anchorID] ?? 0
            let canHit = (now - last) > hitCooldown
            if boxContact && self.isTouching[anchorID] == false && canHit {
                print("head touch box:", "box:",self.fixedY, "head:", actualHeadTop.y)
                self.isTouching[anchorID] = true
                lastHitTime[anchorID] = now
                self.whenHeadTouchBox(model: boxAnchor.children.first! as! ModelEntity)
            }
            if actualHeadTop.y < self.fixedY && !boxContact && self.isTouching[anchorID] == true {
                print("head not touching: box:",self.fixedY, "head:", actualHeadTop.y)
                self.isTouching[anchorID] = false
            }
            //      Perbarui hanya X dan Z
            let newPos = SIMD3<Float>(actualHeadTop.x, self.fixedY, actualHeadTop.z)
            boxAnchor.position = newPos
        }
    }
    
    // Saat Wajah tidak terdeteksi
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        for anchor in anchors {
            guard anchor is ARFaceAnchor else { continue }
            let id = anchor.identifier
            
            if let box = self.boxAnchors[id] {
                box.removeFromParent()
            }
            self.boxAnchors.removeValue(forKey: id)
        }
    }
    
    func getConfig() -> ARConfiguration {
        return self.configuration
    }
}

extension ActivityARJumpViewModel {
    
    func whenHeadTouchBox(model: ModelEntity) {
//        let model = anchor.children.first!
        
        var targetScale: SIMD3<Float>
        if model == self.models[0] {
            self.score += 1
            targetScale = [0.8, 1.5, 0.8]
        } else {
            targetScale = [1.4, 1.6, 1.4]
            self.score = max(self.score - 1, 0)
        }
        
        let animation = ARAnimationService.objectHitAnimation(model: model, targetScale: targetScale)
        let controller: AnimationPlaybackController = model.playAnimation(animation, transitionDuration: 0.05)
        let duration: TimeInterval = controller.duration
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            let randIndex = Int.random(in: 0...(self.models.count - 1))
            self.boxAnchors.forEach { (key: UUID, boxAnchor: AnchorEntity) in
                boxAnchor.children.removeAll()
                let index = self.boxAnchors.first?.value == boxAnchor ? randIndex : (randIndex + 1) % self.models.count
                boxAnchor.addChild(self.models[index])
            }
            //        self.delegate?.whenHeadTouchBox()
            
        }
    }
}
