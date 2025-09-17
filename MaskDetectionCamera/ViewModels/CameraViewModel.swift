//
//  CameraViewModel.swift
//  MaskDetectionCamera
//
//  Created by Franky on 17/09/25.
//

import Foundation
import CoreImage
import Vision

@Observable
class CameraViewModel {
    var currentFrame: CGImage?
    var detectedFaces: [VNFaceObservation] = []
    var faceClassifications: [String: MaskDetectionResult.Classification] = [:]
    
    private let cameraManager = CameraManager()
    private let maskDetectionManager = MaskDetectionManager()
    
    init() {
        Task {
            await handleCameraPreviews()
        }
    }
    
    func handleCameraPreviews() async {
        for await (image, faces) in cameraManager.previewStream {
            Task { @MainActor in
                currentFrame = image
                detectedFaces = faces
                
                // Process mask detection for each face
                processFacesForMaskDetection(image: image, faces: faces)
            }
        }
    }
    
    private func processFacesForMaskDetection(image: CGImage, faces: [VNFaceObservation]) {
        for (index, face) in faces.enumerated() {
            let faceKey = "face_\(index)"
            
            // Crop the face from the full image
            guard let faceImage = maskDetectionManager.cropFaceFromImage(image, faceObservation: face) else {
                continue
            }
            
            // Perform mask detection on the cropped face
            maskDetectionManager.detectMask(in: faceImage) { [weak self] result in
                Task { @MainActor in
                    switch result {
                    case .success(let classification):
                        self?.faceClassifications[faceKey] = classification
                    case .error(let errorMessage):
                        print("Mask detection error for \(faceKey): \(errorMessage)")
                        // Optionally remove the classification if there's an error
                        self?.faceClassifications.removeValue(forKey: faceKey)
                    }
                }
            }
        }
        
        // Clean up classifications for faces that are no longer detected
        let currentFaceKeys = Set(faces.indices.map { "face_\($0)" })
        let storedKeys = Set(faceClassifications.keys)
        let keysToRemove = storedKeys.subtracting(currentFaceKeys)
        
        for key in keysToRemove {
            faceClassifications.removeValue(forKey: key)
        }
    }
}
