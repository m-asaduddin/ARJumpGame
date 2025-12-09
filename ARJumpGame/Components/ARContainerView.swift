//
//  ARViewContainer.swift
//  AruNanda
//
//  Created by Asad on 13/11/25.
//
import SwiftUI
import RealityKit
import ARKit

struct ARContainerView: UIViewRepresentable {
    var sessionDelegate: ARViewSession
    
    init(sessionDelegate: ARViewSession){
        self.sessionDelegate = sessionDelegate
//        let configuration = AR
//        self.viewModel = ARContainerViewModel(sessionDelegate: sessionDelegate, configuration: configuration, modelPath: modelPath)
    }
    
    func makeUIView(context: Context) ->ARView {
        let arView = ARView(frame: .zero)
        let configuration = context.coordinator.getConfig()
        
        arView.session.delegate = context.coordinator
        context.coordinator.arView = arView
        configuration.isLightEstimationEnabled = true
        
        arView.session.run(configuration)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    func makeCoordinator() -> ARViewSession {
        return self.sessionDelegate
    }
    
}
