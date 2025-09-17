//
//  CameraManager.swift
//  MaskDetectionCamera
//
//  Created by Franky on 17/09/25.
//

import AVFoundation
import CoreImage
import Vision


class CameraManager: NSObject {
    
    private let captureSession = AVCaptureSession()
    private var deviceInput: AVCaptureDeviceInput?
    private var videoOutput: AVCaptureVideoDataOutput?
    private let systemPreferredCamera = AVCaptureDevice.default(for: .video)
    // Select front-facing camera
//    private let systemPreferredCamera = AVCaptureDevice.devices(for: .video).first { $0.position == .front }

    private var sessionQueue = DispatchQueue(label: "video.preview.session")
    
    private var addToPreviewStream: ((CGImage, [VNFaceObservation]) -> Void)?
    
    // Vision request for face detection
    private lazy var faceDetectionRequest: VNDetectFaceRectanglesRequest = {
        let request = VNDetectFaceRectanglesRequest()
        request.revision = VNDetectFaceRectanglesRequestRevision3
        return request
    }()
    
    lazy var previewStream: AsyncStream<(CGImage, [VNFaceObservation])> = {
            AsyncStream { continuation in
                addToPreviewStream = { cgImage, faces in
                    continuation.yield((cgImage, faces))
                }
            }
        }()
    
    private var isAuthorized: Bool {
        get async {
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            
            // Determine if the user previously authorized camera access.
            var isAuthorized = status == .authorized
            
            // If the system hasn't determined the user's authorization status,
            // explicitly prompt them for approval.
            if status == .notDetermined {
                isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
            }
            
            return isAuthorized
        }
    }
    
    override init() {
        super.init()
        
        Task {
            await configureSession()
            await startSession()
        }
        
    }
    
    private func configureSession() async {
        guard await isAuthorized,
              let systemPreferredCamera,
              let deviceInput = try? AVCaptureDeviceInput(device: systemPreferredCamera)
        else { return }
        
        captureSession.beginConfiguration()
        
        defer {
            self.captureSession.commitConfiguration()
        }
        
        let videoOutput = AVCaptureVideoDataOutput()
       
        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        
        guard captureSession.canAddInput(deviceInput) else {
            return
        }
        
        guard captureSession.canAddOutput(videoOutput) else {
            return
        }
        
        captureSession.addInput(deviceInput)
        captureSession.addOutput(videoOutput)

        //For a vertical orientation of the camera stream
        videoOutput.connection(with: .video)?.videoRotationAngle = 90
    }
    
    
    private func startSession() async {
        guard await isAuthorized else { return }
        captureSession.startRunning()
    }
    
    private func rotate(by angle: CGFloat, from connection: AVCaptureConnection) {
        guard connection.isVideoRotationAngleSupported(angle) else { return }
        connection.videoRotationAngle = angle
    }
    
    private func detectFaces(in cgImage: CGImage) -> [VNFaceObservation] {
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try requestHandler.perform([faceDetectionRequest])
            return faceDetectionRequest.results ?? []
        } catch {
            print("Face detection error: \(error)")
            return []
        }
    }

}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let currentFrame = sampleBuffer.cgImage else {
            print("Can't translate to CGImage")
            return
        }
        
        // Perform face detection
        let faces = detectFaces(in: currentFrame)
        addToPreviewStream?(currentFrame, faces)
    }
    
}


extension CMSampleBuffer {
    var cgImage: CGImage? {
        let pixelBuffer: CVPixelBuffer? = CMSampleBufferGetImageBuffer(self)
        guard let imagePixelBuffer = pixelBuffer else { return nil }
        return CIImage(cvPixelBuffer: imagePixelBuffer).cgImage
    }
}

extension CIImage {
    var cgImage: CGImage? {
        let ciContext = CIContext()
        guard let cgImage = ciContext.createCGImage(self, from: self.extent) else { return nil }
        return cgImage
    }
}
