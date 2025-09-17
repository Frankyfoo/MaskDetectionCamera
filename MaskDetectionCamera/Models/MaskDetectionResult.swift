//
//  MaskDetectionResult.swift
//  MaskDetectionCamera
//
//  Created by Franky on 17/09/25.
//

//enum MaskDetectionResult {
//    case success(Classification)
//    case error(String)
//    
//    struct Classification {
//        let maskType: MaskType
//        let confidence: Float
//        let className: String
//        
//        // Computed property for backward compatibility
//        var hasMask: Bool {
//            return maskType == .withMask
//        }
//    }
//    
//    enum MaskType {
//        case withMask
//        case withoutMask
//        
//        var displayName: String {
//            switch self {
//            case .withMask:
//                return "Mask"
//            case .withoutMask:
//                return "No Mask"
//            }
//        }
//        
//        var color: String {
//            switch self {
//            case .withMask:
//                return "green"
//            case .withoutMask:
//                return "red"
//            }
//        }
//    }
//}
//
//extension MaskDetectionResult.Classification {
//    var displayText: String {
//        let percentage = Int(confidence * 100)
//        return "\(maskType.displayName) (\(percentage)%)"
//    }
//    
//    var color: String {
//        return maskType.color
//    }
//}

enum MaskDetectionResult {
    case success(Classification)
    case error(String)
    
    struct Classification {
        let maskType: MaskType
        let confidence: Float
        let className: String
        
        // Computed property for backward compatibility
        var hasMask: Bool {
            return maskType == .withMask
        }
    }
    
    enum MaskType {
        case withMask
        case withoutMask
        
        var displayName: String {
            switch self {
            case .withMask:
                return "Mask"
            case .withoutMask:
                return "No Mask"
            }
        }
        
        var color: String {
            switch self {
            case .withMask:
                return "green"
            case .withoutMask:
                return "red"
            }
        }
    }
}

extension MaskDetectionResult.Classification {
    var displayText: String {
        let percentage = Int(confidence * 100)
        return "\(maskType.displayName) (\(percentage)%)"
    }
    
    var color: String {
        return maskType.color
    }
}
