import Foundation

struct GenerateRequest: Codable { let topic:String; let brand:String; let contentType:String; let dialect:String; let tone:String }
struct GenerateResponse: Codable { let text:String?; let provider:String?; let error:String? }

enum APIError: LocalizedError { case invalidURL, badResponse, server(String); var errorDescription:String? { switch self { case .invalidURL:return "رابط الخادم غير صالح."; case .badResponse:return "تعذر قراءة استجابة الخادم."; case .server(let m):return m } } }

actor APIClient {
    static let shared = APIClient()
    private let defaultBaseURL = "https://social-studio-ar-fa-alotaibis-projects.vercel.app"
    func generate(_ body:GenerateRequest, customBaseURL:String?) async throws -> GenerateResponse {
        let base = (customBaseURL?.isEmpty == false ? customBaseURL! : defaultBaseURL).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: base + "/api/generate") else { throw APIError.invalidURL }
        var req = URLRequest(url:url); req.httpMethod = "POST"; req.timeoutInterval = 35; req.setValue("application/json", forHTTPHeaderField:"Content-Type"); req.httpBody = try JSONEncoder().encode(body)
        let (data,response) = try await URLSession.shared.data(for:req)
        guard let http = response as? HTTPURLResponse else { throw APIError.badResponse }
        let decoded = try JSONDecoder().decode(GenerateResponse.self, from:data)
        guard (200..<300).contains(http.statusCode) else { throw APIError.server(decoded.error ?? "تعذر التوليد") }
        return decoded
    }
}
