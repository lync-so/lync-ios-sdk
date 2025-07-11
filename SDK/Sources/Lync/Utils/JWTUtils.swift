import Foundation

/// JWT utility for decoding tokens and extracting payload data
public struct JWTUtils {
    
    /// JWT payload structure containing token name and entity_id
    public struct JWTPayload: Codable {
        public let tokenName: String?
        public let entityId: String?
        public let exp: Int?
        public let iat: Int?
        public let iss: String?
        public let aud: String?
        
        enum CodingKeys: String, CodingKey {
            case tokenName = "token_name"
            case entityId = "entity_id"
            case exp, iat, iss, aud
        }
    }
    
    /// JWT decoding errors
    public enum JWTError: Error, LocalizedError {
        case invalidTokenFormat
        case invalidBase64
        case invalidJSON
        case missingPayload
        case expiredToken
        case invalidSignature
        
        public var errorDescription: String? {
            switch self {
            case .invalidTokenFormat:
                return "Invalid JWT token format"
            case .invalidBase64:
                return "Invalid Base64 encoding in JWT"
            case .invalidJSON:
                return "Invalid JSON in JWT payload"
            case .missingPayload:
                return "Missing payload in JWT"
            case .expiredToken:
                return "JWT token has expired"
            case .invalidSignature:
                return "Invalid JWT signature"
            }
        }
    }
    
    /// Decode a JWT token and extract the payload
    /// - Parameter token: The JWT token string
    /// - Returns: Decoded JWT payload containing token name and entity_id
    /// - Throws: JWTError if the token is invalid or expired
    public static func decode(_ token: String) throws -> JWTPayload {
        // Split the JWT into parts
        let parts = token.components(separatedBy: ".")
        guard parts.count == 3 else {
            throw JWTError.invalidTokenFormat
        }
        
        // Decode the payload (second part)
        let payloadString = parts[1]
        guard let payloadData = base64URLDecode(payloadString) else {
            throw JWTError.invalidBase64
        }
        
        // Parse the JSON payload
        do {
            let payload = try JSONDecoder().decode(JWTPayload.self, from: payloadData)
            
            // Check if token is expired
            if let exp = payload.exp {
                let currentTime = Int(Date().timeIntervalSince1970)
                if currentTime > exp {
                    throw JWTError.expiredToken
                }
            }
            
            return payload
        } catch {
            throw JWTError.invalidJSON
        }
    }
    
    /// Extract token name from JWT
    /// - Parameter token: The JWT token string
    /// - Returns: Token name if present in the payload
    /// - Throws: JWTError if the token is invalid
    public static func extractTokenName(from token: String) throws -> String? {
        let payload = try decode(token)
        return payload.tokenName
    }
    
    /// Extract entity_id from JWT
    /// - Parameter token: The JWT token string
    /// - Returns: Entity ID if present in the payload
    /// - Throws: JWTError if the token is invalid
    public static func extractEntityId(from token: String) throws -> String? {
        let payload = try decode(token)
        return payload.entityId
    }
    
    /// Extract both token name and entity_id from JWT
    /// - Parameter token: The JWT token string
    /// - Returns: Tuple containing token name and entity_id (either can be nil)
    /// - Throws: JWTError if the token is invalid
    public static func extractTokenInfo(from token: String) throws -> (tokenName: String?, entityId: String?) {
        let payload = try decode(token)
        return (tokenName: payload.tokenName, entityId: payload.entityId)
    }
    
    /// Check if JWT token is expired
    /// - Parameter token: The JWT token string
    /// - Returns: True if token is expired, false otherwise
    /// - Throws: JWTError if the token is invalid
    public static func isExpired(_ token: String) throws -> Bool {
        let payload = try decode(token)
        guard let exp = payload.exp else {
            return false // No expiration time set
        }
        
        let currentTime = Int(Date().timeIntervalSince1970)
        return currentTime > exp
    }
    
    /// Get token expiration date
    /// - Parameter token: The JWT token string
    /// - Returns: Expiration date if present in the payload
    /// - Throws: JWTError if the token is invalid
    public static func getExpirationDate(_ token: String) throws -> Date? {
        let payload = try decode(token)
        guard let exp = payload.exp else {
            return nil
        }
        return Date(timeIntervalSince1970: TimeInterval(exp))
    }
    
    /// Get token issuance date
    /// - Parameter token: The JWT token string
    /// - Returns: Issuance date if present in the payload
    /// - Throws: JWTError if the token is invalid
    public static func getIssuanceDate(_ token: String) throws -> Date? {
        let payload = try decode(token)
        guard let iat = payload.iat else {
            return nil
        }
        return Date(timeIntervalSince1970: TimeInterval(iat))
    }
    
    // MARK: - Private Methods
    
    /// Decode Base64URL string to Data
    private static func base64URLDecode(_ string: String) -> Data? {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        // Add padding if needed
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }
        
        return Data(base64Encoded: base64)
    }
}

// MARK: - Convenience Extensions

extension JWTUtils {
    
    /// Safely decode JWT without throwing errors
    /// - Parameter token: The JWT token string
    /// - Returns: Decoded payload or nil if decoding fails
    public static func safeDecode(_ token: String) -> JWTPayload? {
        do {
            return try decode(token)
        } catch {
            #if DEBUG
            print("❌ JWT decode error: \(error)")
            #endif
            return nil
        }
    }
    
    /// Safely extract token name without throwing errors
    /// - Parameter token: The JWT token string
    /// - Returns: Token name or nil if extraction fails
    public static func safeExtractTokenName(from token: String) -> String? {
        do {
            return try extractTokenName(from: token)
        } catch {
            #if DEBUG
            print("❌ JWT token name extraction error: \(error)")
            #endif
            return nil
        }
    }
    
    /// Safely extract entity_id without throwing errors
    /// - Parameter token: The JWT token string
    /// - Returns: Entity ID or nil if extraction fails
    public static func safeExtractEntityId(from token: String) -> String? {
        do {
            return try extractEntityId(from: token)
        } catch {
            #if DEBUG
            print("❌ JWT entity_id extraction error: \(error)")
            #endif
            return nil
        }
    }
}

// MARK: - Usage Examples

/*
 
 // Basic JWT decoding
 do {
     let payload = try JWTUtils.decode("your.jwt.token")
     print("Token name: \(payload.tokenName ?? "nil")")
     print("Entity ID: \(payload.entityId ?? "nil")")
 } catch {
     print("JWT decode error: \(error)")
 }
 
 // Extract specific fields
 let tokenName = try? JWTUtils.extractTokenName(from: "your.jwt.token")
 let entityId = try? JWTUtils.extractEntityId(from: "your.jwt.token")
 
 // Safe extraction (no throws)
 let safeTokenName = JWTUtils.safeExtractTokenName(from: "your.jwt.token")
 let safeEntityId = JWTUtils.safeExtractEntityId(from: "your.jwt.token")
 
 // Check expiration
 let isExpired = try? JWTUtils.isExpired("your.jwt.token")
 let expirationDate = try? JWTUtils.getExpirationDate("your.jwt.token")
 
 */ 