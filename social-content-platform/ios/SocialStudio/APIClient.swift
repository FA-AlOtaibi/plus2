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
            "gulf": "خليجية سعودية طبيعية ومعاصرة بدون تكلف",
            "msa": "عربية فصحى سليمة وطبيعية غير متخشبة",
            "egyptian": "مصرية طبيعية معاصرة",
            "levantine": "شامية طبيعية معاصرة"
        ][dialect] ?? "خليجية سعودية طبيعية"

        let toneName = [
            "friendly": "ودودة وذكية",
            "formal": "رسمية وواثقة",
            "bold": "جريئة لكن منضبطة",
            "funny": "خفيفة الظل بدون تهريج",
            "inspiring": "ملهمة بدون مبالغة"
        ][tone] ?? "ودودة وذكية"

        let lengthRule: String
        let maxTokens: Int
        switch contentType {
        case "tweets":
            lengthRule = "التغريدة يجب أن تكون قصيرة وقابلة للنشر مباشرة، والأفضل 120–240 حرفاً، ولا تتجاوز تقريباً 280 حرفاً. لا تحولها إلى مقال."
            maxTokens = 220
        case "thread":
            lengthRule = "الثريد من 3 إلى 6 أجزاء قصيرة، وكل جزء يضيف معنى جديداً بلا حشو."
            maxTokens = 850
        case "caption":
            lengthRule = "الكابشن متوسط الطول، مريح بصرياً، وفقراته قصيرة."
            maxTokens = 420
        case "linkedin":
            lengthRule = "منشور LinkedIn مهني ومتماسك، بلا مبالغات تسويقية طفولية."
            maxTokens = 650
        default:
            lengthRule = "الإعلان مركز ومقنع، فيه عرض واضح وCTA طبيعي، بلا حشو."
            maxTokens = 420
        }

        let system = """
أنت كاتب إعلانات ومحتوى عربي ممتاز، لكن الأولوية للدقة والطبيعية قبل الإبداع. اكتب نصاً يصلح أن ينشره شخص حقيقي الآن، لا نصاً استعراضياً ولا كلاماً غريباً.

افهم المدخلات أولاً كحقائق مُعطاة. ثم استنبط فقط ما يمكن استنباطه منطقياً منها، بدون اختراع أحداث أو مشاعر أو فوائد أو تجارب شخصية لم يذكرها المستخدم.

قواعد إلزامية:
1) كل معلومة واقعية في النص النهائي يجب أن تكون موجودة في مدخل المستخدم أو نتيجة منطقية مباشرة جداً منها.
2) ممنوع اختراع قصة شخصية أو موقف مثل: «جربت؟»، «أبوك يحب...»، «يفكر فيك»، «قهوة الصباح»، «تذكرك به»، إلا إذا ذكره المستخدم فعلاً.
3) ممنوع اختراع فوائد صحية أو طبية أو وعود أداء. إذا ذكر المستخدم كلاماً مثل الطاقة أو عدم النعاس، لا تضخمه ولا تحوله لوعد طبي؛ يمكنك صياغته بشكل ألطف مثل «يناسب بداية يومك».
4) لا تستخدم استعارات غريبة أو شاعرية مبالغ فيها من نوع «صباحك نصه مكتوب» أو جمل تبدو عميقة وهي بلا معنى.
5) لا تكرر مدخل المستخدم حرفياً. خذ حقائقه وابنِ منها رسالة أوضح وأجمل.
6) لا تستخدم افتتاحيات محفوظة مثل: بدون لف ودوران، الفكرة بسيطة، خلنا نقولها، المشكلة والحل، ثلاث أشياء، مو لازم العرض يصرخ.
7) لا تضع إيموجي إلا إذا النبرة أو السياق يستدعيه فعلاً، وبحد أقصى واحد في التغريدة.
8) لا تكتب أي شرح عن طريقة الكتابة. أخرج النص النهائي فقط.
9) اكتب بلهجة \(dialectName)، بنبرة \(toneName)، وبصيغة \(formatName).
10) \(lengthRule)

قبل الإخراج، راجع النص داخلياً واسأل: هل فيه شيء اخترعته؟ هل فيه جملة محرجة أو مصطنعة؟ هل يصلح فعلاً أن ينشره متجر أو شخص؟ إذا لا، أعد صياغته قبل الإخراج.

الإبداع المطلوب هنا هو اختيار زاوية وترتيب وصوت أفضل، لا اختراع وقائع جديدة.
"""

        let user = """
هذه هي المعلومات الوحيدة الموثوقة التي يجوز لك البناء عليها:
\(topic)

تعليمات وهوية إضافية:
\(instruction)

\(extraAvoidance)

اكتب النسخة النهائية فقط. لا تضف مقدمة أو ملاحظات.
"""

        let body = HFRequest(
            model: hfModel,
            messages: [
                HFMessage(role: "system", content: system),
                HFMessage(role: "user", content: user)
            ],
            temperature: 0.82,
            top_p: 0.88,
            max_tokens: maxTokens,
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
