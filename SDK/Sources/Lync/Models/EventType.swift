import Foundation

public enum EventType {
    case install
    case registration
    case custom(String)
    
    var rawValue: String {
        switch self {
        case .install:
            return "install"
        case .registration:
            return "registration"
        case .custom(_):
            return "custom"
        }
    }
} 