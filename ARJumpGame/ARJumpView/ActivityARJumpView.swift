//
//  ActivityARJumpView.swift
//  AruNanda
//
//  Created by Asad on 13/11/25.
//
import SwiftUI
import ARKit


struct ActivityARJumpView: View {
    @StateObject var viewModel = ActivityARJumpViewModel(modelsPath: ["Coin.usdz", "Bomb.usdz"])
    
    var body: some View {
        ZStack {
            ARContainerView(sessionDelegate: viewModel)
                .ignoresSafeArea()
            VStack {
                HStack{
                    Text("Score : ")
                    Text(viewModel.score.formatted())
                }
                .foregroundStyle(.white)
                .font(.largeTitle)
                .shadow(radius: 2)
                .shadow(radius: 2)
                .shadow(radius: 2)
                Spacer()
            }
        }
//        .overlay(
//            OrientationLockViewController(orientation: .landscapeRight)
//                .frame(width: 0, height: 0)
//        )
//        .previewInterfaceOrientation(.landscapeRight)
    }
}
