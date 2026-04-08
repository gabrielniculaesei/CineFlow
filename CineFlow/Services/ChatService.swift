import Foundation

class ChatService {
    static let shared = ChatService()
    private let session = URLSession.shared
    
    struct ChatMessage: Identifiable, Equatable {
        let id = UUID()
        let role: Role
        let content: String
        let timestamp = Date()
        
        enum Role: String {
            case user
            case assistant
        }
    }
    
    func sendMessage(userMessage: String, history: [ChatMessage]) async throws -> String {
        let url = URL(string: "\(APIConfig.mlAPIBaseURL)/chat")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60
        
        let body: [String: Any] = [
            "message": userMessage,
            "temperature": 0.7
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw ChatError.serviceUnavailable
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChatError.invalidResponse
        }
        
        if httpResponse.statusCode == 503 {
            throw ChatError.serviceUnavailable
        }
        
        if httpResponse.statusCode != 200 {
            throw ChatError.httpError(httpResponse.statusCode)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["response"] as? String else {
            throw ChatError.invalidResponse
        }
        
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum ChatError: LocalizedError {
    case invalidResponse
    case httpError(Int)
    case serviceUnavailable
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Couldn't understand the response"
        case .httpError(let code): return "Server error (\(code))"
        case .serviceUnavailable: return "SERVICE_UNAVAILABLE"
        }
    }
}
