import Foundation

public enum LyncError: Error {
    case invalidURL
    case invalidResponse
    case apiError(Int, String)
    
    public var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .apiError(let code, let message):
            return "API Error \(code): \(message)"
        }
    }
} 