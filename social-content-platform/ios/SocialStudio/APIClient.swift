import Foundation

struct GenerateRequest: Codable {
    let topic: String
    let brand: String
    let contentType: String
    let dialect: String
    let tone: String
}

struct GenerateResponse: Codable {
    let text: String?
    let provider: String?
    let error: String?
}

private struct HFMessage: Codable {
    let role: String
    let content: String
}

private struct HFRequest: Codable {
    let model: String
    let messages: [HFMessage]
    let temperature: Double
    let top_p: Double
    let max_tokens: Int
    let stream: Bool
}

private struct HFResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable { let content: String? }
        let message: Message
    }
    let choices: [Choice]?
    let error: HFError?
}

private struct HFError: Codable { let message: String? }

enum APIError: LocalizedError {
    case invalidURL, badResponse, server(String)
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "رابط الخادم غير صالح."
        case .badResponse: return "تعذر قراءة استجابة الخادم."
        case .server(let message): return message
        }
    }
}

actor APIClient {
    static let shared = APIClient()
    private let defaultBaseURL = "https://social-studio-ar.vercel.app"
    private let hfURL = URL(string: "https://router.huggingface.co/v1/chat/completions")!
    private let hfModel = "Qwen/Qwen3-235B-A22B-Instruct-2507:fastest"

    func generate(_ body: GenerateRequest, customBaseURL: String?) async throws -> GenerateResponse {
        let base = (customBaseURL?.isEmpty == false ? customBaseURL! : defaultBaseURL)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: base + "/api/generate") else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.badResponse }
        guard let decoded = try? JSONDecoder().decode(GenerateResponse.self, from: data) else {
            let raw = String(data: data, encoding: .utf8) ?? ""
            throw APIError.server(raw.isEmpty ? "تعذر قراءة استجابة محرك الذكاء الاصطناعي." : raw)
        }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.server(decoded.error ?? "تعذر التوليد من الخادم.")
        }
        return decoded
    }

    func generateWithHuggingFace(
        token: String,
        topic: String,
        instruction: String,
        contentType: String,
        dialect: String,
        tone: String,
        extraAvoidance: String = ""
    ) async throws -> GenerateResponse {
        let cleanToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanToken.hasPrefix("hf_") else {
            throw APIError.server("توكن Hugging Face غير صالح أو غير مكتمل.")
        }

        let formatName = [
            "tweets": "تغريدة واحدة",
            "thread": "ثريد",
            "caption": "كابشن",
            "linkedin": "منشور LinkedIn",
            "ad": "إعلان"
        ][contentType] ?? "منشور"

        let dialectName = [
            "gulf": "خليجية طبيعية معاصرة",
            "msa": "عربية فصحى طبيعية",
            "egyptian": "مصرية طبيعية",
            "levantine": "شامية طبيعية"
        ][dialect] ?? "خليجية طبيعية"

        let requestedStyle = tone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "طبيعي، واضح، بشري، مختصر، بدون مبالغة"
            : tone.trimmingCharacters(in: .whitespacesAndNewlines)

        let system = """
أنت محرر عربي محترف. أهم قاعدة: أسلوب الكتابة يحدده المستخدم بنفسه، وليس عندك قالب جاهز.

نفّذ الطلب بهذا الترتيب:
1) افهم الحقائق الموجودة في الفكرة الخام.
2) التزم حرفياً بتوجيه المستخدم لطريقة الكلام.
3) اكتب النص النهائي فقط.

الأسلوب المطلوب من المستخدم:
\(requestedStyle)

قواعد لا تكسرها:
- لا تضف أي حقيقة، فائدة، تجربة، شعور، قصة، علاقة، صفة، أو وعد غير موجود في المدخلات، إلا إذا طلب المستخدم صراحة أن تستنبط أو تتخيل ذلك في خانة الأسلوب.
- لا تقل: "هل جربت" أو "أبوك" أو "لو تحب" أو أي موقف شخصي لم يذكره المستخدم.
- لا تضف فوائد صحية أو طاقة أو نشاط إلا إذا كانت مذكورة صراحة في الفكرة الخام.
- لا تحول النص إلى كلام شاعري أو عاطفي من عندك.
- لا تستخدم لغة تسويقية محفوظة أو عبارات AI مثل: اختيار بسيط، يلمع في وقته، يخلي صباحك، مو مجرد، بدون لف ودوران، الفكرة بسيطة.
- لا تكرر الفكرة حرفياً كسطور متتابعة؛ أعد بناء الصياغة وفق أسلوب المستخدم، لكن حافظ على المعنى والحقائق.
- اكتب بلهجة \(dialectName) وبصيغة \(formatName).
- إذا كانت تغريدة، اجعلها موجزة وقابلة للنشر، ويفضل ألا تتجاوز 280 حرفاً ما لم يطلب المستخدم غير ذلك.
- علامات الترقيم والإيموجي والطول كلها تتبع وصف المستخدم إن ذكرها.
- لا تشرح ما فعلته ولا تكتب عناوين مثل "الصياغة" أو "النص".
"""

        let user = """
الفكرة الخام:
\(topic)

تعليمات الجودة والسياق:
\(instruction)

\(extraAvoidance)

اكتب النسخة النهائية الآن، ملتزماً أولاً بطريقة الكلام التي كتبها المستخدم.
"""

        let body = HFRequest(
            model: hfModel,
            messages: [
                HFMessage(role: "system", content: system),
                HFMessage(role: "user", content: user)
            ],
            temperature: 0.72,
            top_p: 0.90,
            max_tokens: contentType == "thread" ? 900 : 420,
            stream: false
        )

        var request = URLRequest(url: hfURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 75
        request.setValue("Bearer \(cleanToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.badResponse }
        guard let decoded = try? JSONDecoder().decode(HFResponse.self, from: data) else {
            let raw = String(data: data, encoding: .utf8) ?? ""
            throw APIError.server(raw.isEmpty ? "تعذر قراءة استجابة Hugging Face." : raw)
        }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.server(decoded.error?.message ?? "Hugging Face رفض الطلب (\(http.statusCode)).")
        }
        let text = decoded.choices?.first?.message.content?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !text.isEmpty else { throw APIError.server("النموذج رجع نتيجة فارغة.") }
        return GenerateResponse(text: text, provider: "QWEN3-HF", error: nil)
    }
}
