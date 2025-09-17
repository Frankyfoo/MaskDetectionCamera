//
//  ContentView.swift
//  MaskDetectionCamera
//
//  Created by Franky on 17/09/25.
//

import SwiftUI

struct ContentView: View {
    
    @State private var viewModel = CameraViewModel()
    
    var body: some View {
        CameraView(
            image: $viewModel.currentFrame,
            faces: $viewModel.detectedFaces,
            faceClassifications: $viewModel.faceClassifications
        )
        .overlay(alignment: .top) {
            // Face count and mask detection indicator
            // if there is face in the camera frame, it will run the code below
            if !viewModel.detectedFaces.isEmpty {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "face.smiling")
                            .foregroundColor(.green)
                        Text("\(viewModel.detectedFaces.count) face(s) detected")
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                    
                    // Mask detection summary
                    if !viewModel.faceClassifications.isEmpty {
                        let maskedCount = viewModel.faceClassifications.values.filter { $0.hasMask }.count
                        let totalCount = viewModel.faceClassifications.count
                        
                        HStack {
                            Image(systemName: maskedCount > 0 ? "checkmark.shield" : "exclamationmark.shield")
                                .foregroundColor(maskedCount == totalCount ? .green : .orange)
                            Text("\(maskedCount)/\(totalCount) wearing masks")
                                .foregroundColor(.white)
                                .font(.subheadline)
                        }
                    }
                }
                .padding()
                .background(Color.black.opacity(0.7))
                .cornerRadius(10)
                .padding(.top, 50)
            }
        }
        .overlay(alignment: .bottom) {
            // Legend
            HStack(spacing: 15) {
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(Color.green)
                        .frame(width: 16, height: 3)
                    Text("Correct")
                        .font(.caption2)
                        .foregroundColor(.white)
                }
                
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: 16, height: 3)
                    Text("No Mask")
                        .font(.caption2)
                        .foregroundColor(.white)
                }
                
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: 16, height: 3)
                    Text("Analyzing")
                        .font(.caption2)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.7))
            .cornerRadius(8)
            .padding(.bottom, 50)
        }
    }
}

#Preview {
    ContentView()
}

