//
//  MaskDetectionManager.swift
//  MaskDetectionCamera
//
//  Created by Franky on 17/09/25.
//

import Foundation
import CoreML
import Vision
import CoreImage

class MaskDetectionManager {
    
    private var maskDetectionModel: VNCoreMLModel?
    
    init() {
        loadModel()
    }
    
    private func loadModel() {
        guard let modelURL = Bundle.main.url(forResource: "MaskDetectionModel", withExtension: "mlmodelc") else {
            print("Failed to find model file")
            return
        }
        
        do {
            let mlModel = try MLModel(contentsOf: modelURL)
            maskDetectionModel = try VNCoreMLModel(for: mlModel)
        } catch {
            print("Failed to load model: \(error)")
        }
    }
    
    func detectMask(in faceImage: CGImage, completion: @escaping (MaskDetectionResult) -> Void) {
        guard let model = maskDetectionModel else {
            completion(.error("Model not loaded"))
            return
        }
        
        let request = VNCoreMLRequest(model: model) { request, error in
            if let error = error {
                completion(.error(error.localizedDescription))
                return
            }
            
            guard let results = request.results as? [VNClassificationObservation] else {
                completion(.error("No classification results"))
                return
            }
            
            // Sort results by confidence to get the most confident prediction
            let sortedResults = results.sorted { $0.confidence > $1.confidence }
            
            guard let topResult = sortedResults.first else {
                completion(.error("No classification results"))
                return
            }
            
            // Parse the classification result
            let classification = self.parseClassification(from: topResult)
            completion(.success(classification))
        }
        
        // Configure the request based on your model's input requirements
        request.imageCropAndScaleOption = .scaleFill
        
        let handler = VNImageRequestHandler(cgImage: faceImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                completion(.error("Failed to perform request: \(error)"))
            }
        }
    }
    
    private func parseClassification(from observation: VNClassificationObservation) -> MaskDetectionResult.Classification {
        let identifier = observation.identifier.lowercased()
        let confidence = observation.confidence
        
        // Define classification based on common model outputs
        // Adjust these patterns based on your specific model's class names
        let maskType: MaskDetectionResult.MaskType
        
        if identifier.contains("with_mask") {
            maskType = .withMask
        } else if identifier.contains("without_mask") {
            maskType = .withoutMask
        }
        else {
            // Fallback: try to determine from confidence and common patterns
            if identifier.contains("mask") {
                maskType = .withMask
            } else {
                maskType = .withoutMask
            }
        }
        
        return MaskDetectionResult.Classification(
            maskType: maskType,
            confidence: confidence,
            className: observation.identifier
        )
    }
    
    func cropFaceFromImage(_ image: CGImage, faceObservation: VNFaceObservation) -> CGImage? {
        let imageSize = CGSize(width: image.width, height: image.height)
        
        // Convert normalized coordinates to pixel coordinates
        let faceRect = VNImageRectForNormalizedRect(
            faceObservation.boundingBox,
            Int(imageSize.width),
            Int(imageSize.height)
        )
        
        // Add some padding around the face (but ensure we don't go out of bounds)
        let padding: CGFloat = 20
        let expandedRect = CGRect(
            x: max(0, faceRect.origin.x - padding),
            y: max(0, faceRect.origin.y - padding),
            width: min(imageSize.width - max(0, faceRect.origin.x - padding), faceRect.width + 2 * padding),
            height: min(imageSize.height - max(0, faceRect.origin.y - padding), faceRect.height + 2 * padding)
        )
        
        return image.cropping(to: expandedRect)
    }
}
