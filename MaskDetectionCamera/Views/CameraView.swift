//
//  CameraView.swift
//  MaskDetectionCamera
//
//  Created by Franky on 17/09/25.
//

import SwiftUI
import Vision

struct CameraView: View {
    
    @Binding var image: CGImage?
    @Binding var faces: [VNFaceObservation]
    @Binding var faceClassifications: [String: MaskDetectionResult.Classification]
    
    var body: some View {
        GeometryReader { geometry in
            if let image = image {
                ZStack {
                    // Camera feed
                    Image(decorative: image, scale: 1)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    
                    // Face detection overlay with mask detection
                    FaceDetectionOverlay(
                        faces: faces,
                        faceClassifications: faceClassifications,
                        imageSize: CGSize(width: image.width, height: image.height),
                        viewSize: geometry.size
                    )
                }
            } else {
                ContentUnavailableView("Camera feed interrupted", systemImage: "xmark.circle.fill")
                    .frame(width: geometry.size.width,
                           height: geometry.size.height)
            }
        }
    }
}

struct FaceDetectionOverlay: View {
    let faces: [VNFaceObservation]
    let faceClassifications: [String: MaskDetectionResult.Classification]
    let imageSize: CGSize
    let viewSize: CGSize
    
    var body: some View {
        ForEach(faces.indices, id: \.self) { index in
            let face = faces[index]
            let faceKey = "face_\(index)"
            let classification = faceClassifications[faceKey]
            
            // Convert Vision coordinates to SwiftUI coordinates
            let boundingBox = convertBoundingBox(face.boundingBox)
            
            // Determine box color based on mask detection
            let boxColor: Color = {
                guard let classification = classification else { return .blue }
                switch classification.maskType {
                case .withMask:
                    return .green
                case .withoutMask:
                    return .red
                }
            }()
            
            Rectangle()
                .stroke(boxColor, lineWidth: 3)
                .frame(width: boundingBox.width, height: boundingBox.height)
                .position(x: boundingBox.midX, y: boundingBox.midY)
                .overlay(
                    VStack(spacing: 2) {
                        Text("Face \(index + 1)")
                            .font(.caption2)
                            .fontWeight(.medium)
                        
                        if let classification = classification {
                            Text(classification.displayText)
                                .font(.caption2)
                                .fontWeight(.bold)
                        } else {
                            Text("Analyzing...")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(6)
                    .position(x: boundingBox.midX, y: boundingBox.minY - 20)
                )
        }
    }
    
    private func convertBoundingBox(_ visionBoundingBox: CGRect) -> CGRect {
        // Calculate the scale factor to fit image in view
        let scaleX = viewSize.width / imageSize.width
        let scaleY = viewSize.height / imageSize.height
        let scale = min(scaleX, scaleY)
        
        // Calculate actual displayed image size
        let displayedImageSize = CGSize(
            width: imageSize.width * scale,
            height: imageSize.height * scale
        )
        
        // Calculate offset to center the image
        let offsetX = (viewSize.width - displayedImageSize.width) / 2
        let offsetY = (viewSize.height - displayedImageSize.height) / 2
        
        // Vision coordinates are normalized (0-1) with origin at bottom-left
        // Convert to SwiftUI coordinates (origin at top-left)
        let x = visionBoundingBox.minX * displayedImageSize.width + offsetX
        let y = (1 - visionBoundingBox.maxY) * displayedImageSize.height + offsetY
        let width = visionBoundingBox.width * displayedImageSize.width
        let height = visionBoundingBox.height * displayedImageSize.height
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
}

#Preview {
    CameraView(
        image: .constant(nil),
        faces: .constant([]),
        faceClassifications: .constant([:])
    )
}
