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

private struct HFError: Codable {
    let message: String?
}

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
            "tweets": "تغريدة",
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

        let toneName = [
            "friendly": "ودودة",
            "formal": "رسمية",
            "bold": "جريئة",
            "funny": "فكاهية ذكية",
            "inspiring": "ملهمة"
        ][tone] ?? "ودودة"

        let system = """
أنت مدير إبداعي وكاتب محتوى عربي من أعلى مستوى. مهمتك ليست إعادة صياغة كلام المستخدم، بل فهم الفكرة الخام ثم اكتشاف الزاوية الأقوى وبناء نص جديد فعلاً منها.

قبل الكتابة فكّر داخلياً في عدة زوايا مختلفة ثم اختر الأكثر تميزاً. لا تعرض هذا التفكير للمستخدم.

قواعد حاسمة:
- لا تبدأ بإعادة جملة المستخدم ولا تلخصها حرفياً.
- استنبط السياق، الجمهور المحتمل، المشهد، الدافع، الفائدة العاطفية والعملية، والـHook المناسب من المدخلات.
- ممنوع اختراع أرقام أو أسعار أو خصومات أو مواصفات أو ضمانات غير موجودة.
- مسموح بابتكار تصوير، موقف، قصة قصيرة، سؤال، مفارقة، زاوية هدية، استخدام يومي، إحساس، أو CTA منطقي طالما لا يضيف حقيقة مزيفة.
- كل محاولة يجب أن تختلف جذرياً في الافتتاحية، البناء، الإيقاع، زاوية الإقناع، والخاتمة.
- تجنب لغة الذكاء الاصطناعي والقوالب مثل: الفكرة بسيطة، المشكلة والحل، بدون لف ودوران، ثلاث أشياء، خلنا نقولها، ما يحتاج تعقيد، مو لازم العرض يصرخ.
- لا تشرح للمستخدم كيف كتبت. أخرج النص النهائي فقط.
- اكتب بلهجة \(dialectName)، بنبرة \(toneName)، وبصيغة \(formatName).
- اجعل النص يبدو وكأنه مكتوب من شخص يفهم الإعلان والسرد فعلاً، لا مولد نصوص.
"""

        let user = """
الفكرة الخام:
\(topic)

تعليمات إضافية وهوية/سياق:
\(instruction)

\(extraAvoidance)

اكتب نسخة جديدة كاملة الآن. أعطني النص النهائي فقط.
"""

        let body = HFRequest(
            model: hfModel,
            messages: [
                HFMessage(role: "system", content: system),
                HFMessage(role: "user", content: user)
            ],
            temperature: 1.08,
            top_p: 0.95,
            max_tokens: contentType == "thread" ? 900 : 520,
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
