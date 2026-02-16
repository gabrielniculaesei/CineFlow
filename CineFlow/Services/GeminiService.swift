import Foundation

class OllamaService {
    static let shared = OllamaService()
    private let session = URLSession.shared
    
    private let systemPrompt = """
    You are CineBot, a friendly and knowledgeable movie recommendation assistant inside the CineFlow app. \
    Your personality is warm, enthusiastic about cinema, and concise. \
    Keep responses SHORT (2-4 sentences max) unless the user asks for detail. \
    When recommending movies, always include the year in parentheses. \
    You can discuss any movie-related topic: recommendations, trivia, comparisons, plot explanations, etc. \
    If someone asks something unrelated to movies, gently steer them back to films. \
    Never use markdown formatting — respond in plain text only. \
    When listing movies, use simple numbered lists.
    """
    
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
        let url = URL(string: "\(APIConfig.ollamaBaseURL)/api/chat")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60 // Ollama can be slower than cloud APIs
        
        // Build messages array
        var messages: [[String: String]] = []
        
        // System message
        messages.append([
            "role": "system",
            "content": systemPrompt
        ])
        
        // Add history (limit to last 10 messages to avoid context overflow)
        let recentHistory = history.suffix(10)
        for msg in recentHistory {
            let role = msg.role == .user ? "user" : "assistant"
            messages.append([
                "role": role,
                "content": msg.content
            ])
        }
        
        // Add current user message
        messages.append([
            "role": "user",
            "content": userMessage
        ])
        
        let body: [String: Any] = [
            "model": APIConfig.ollamaModel,
            "messages": messages,
            "stream": false,
            "options": [
                "temperature": 0.8,
                "num_predict": 500
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw OllamaError.serviceUnavailable
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OllamaError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            // Try to parse error from Ollama
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMsg = json["error"] as? String {
                if errorMsg.contains("not found") {
                    throw OllamaError.modelNotFound
                }
            }
            throw OllamaError.httpError(httpResponse.statusCode)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let message = json["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw OllamaError.invalidResponse
        }
        
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum OllamaError: LocalizedError {
    case invalidResponse
    case httpError(Int)
    case serviceUnavailable
    case modelNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Couldn't understand the response"
        case .httpError(let code): return "Server error (\(code))"
        case .serviceUnavailable: return "SERVICE_UNAVAILABLE"
        case .modelNotFound: return "MODEL_NOT_FOUND"
        }
    }
}
