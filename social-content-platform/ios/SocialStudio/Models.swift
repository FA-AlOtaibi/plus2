import Foundation

struct HistoryItem: Identifiable, Codable {
    let id: UUID
    let createdAt: Date
    let topic: String
    let text: String
    let type: String
}

private enum CreativeWriter {
    static func compose(topic: String, type: String, dialect: String, tone: String) -> String {
        let clean = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = clean.lowercased()
        let isApp = lower.contains("تطبيق") || lower.contains("موقع") || lower.contains("منصة")
        let isWriting = lower.contains("فكرة") || lower.contains("سرد") || lower.contains("كتابة") || lower.contains("محتوى")
        let isFood = lower.contains("مطعم") || lower.contains("قهوة") || lower.contains("برجر") || lower.contains("أكل")
        let isProduct = lower.contains("منتج") || lower.contains("متجر") || lower.contains("خدمة")

        let hook: String
        let middle: String
        let close: String

        if isApp && isWriting {
            hook = "مو كل فكرة تحتاج كاتب… أحياناً تحتاج أحد يعرف يلقط معناها ويعطيها صوتها الصحيح."
            middle = "هذا بالضبط اللي تحاول تسويه فكرتك: تبدأ من الكلام الخام كما هو في بالك، ثم ترتبه وتوسّعه وتستخرج منه الزاوية الأقوى، بدون ما تضيع النبرة أو يتحول النص إلى كلام محفوظ. بدل صفحة بيضاء، يصير عندك مسودة تعرف وش تقول، ولمين تقولها، وكيف تخليها أسهل في القراءة وأقوى في الأثر."
            close = "الفكرة الأصلية: \(clean)\nوالقيمة الحقيقية فيها إن المستخدم ما يبحث عن كلمات أكثر؛ يبحث عن صياغة أفضل لنفس فكرته."
        } else if isFood {
            hook = "الفرق مو في إنك تقدم شيء يؤكل… الفرق في التجربة اللي تخلي الناس تتذكره وترجع له."
            middle = "من وصفك، الفكرة تقدر تُبنى حول الإحساس قبل المنتج: لحظة الطلب، التفاصيل الصغيرة، والطابع اللي يخلي المكان أو الطبق له شخصية بدل ما يكون نسخة من غيره."
            close = "\(clean)\nخل الرسالة تبيع الشعور قبل ما تبيع الصنف."
        } else if isProduct {
            hook = "المنتج الجيد يحل حاجة، لكن المنتج اللي يعلق في الذهن يشرح فائدته قبل ما يضطر يشرح نفسه."
            middle = "الفكرة هنا قابلة للتحويل إلى رسالة أوضح: ما الذي تختصره على المستخدم؟ ما الذي تجعله أسهل؟ ولماذا سيختارك بدل البدائل؟ هذه الزوايا هي اللي تحول الوصف من قائمة مزايا إلى قصة مفهومة."
            close = "\(clean)\nابدأ بالقيمة، ثم خل التفاصيل تخدمها."
        } else {
            hook = "في فكرتك زاوية أقوى من مجرد وصفها حرفياً."
            middle = "بدل إعادة نفس الجملة، نقدر نبني حولها معنى: لماذا تهم؟ ما التغيير الذي تعد به؟ وما الشيء الذي يفهمه القارئ بعد ثوانٍ؟ الصياغة الأقوى تأخذ فكرتك كما هي، ثم تستنبط منها السبب، الفائدة، والصورة التي تستحق أن تبقى في ذهن القارئ."
            close = "الفكرة: \(clean)\nالهدف: نخليها مفهومة، لها شخصية، وتوصل بدون حشو."
        }

        let base: String
        switch type {
        case "thread":
            base = "1/ \(hook)\n\n2/ \(middle)\n\n3/ \(close)"
        case "caption":
            base = "\(hook)\n\n\(middle)\n\n\(close)"
        case "linkedin":
            base = "\(hook)\n\nأكثر شيء مهم في \(clean) هو الانتقال من الفكرة الخام إلى قيمة واضحة للمستخدم.\n\n\(middle)\n\n\(close)"
        case "ad":
            base = "\(hook)\n\n\(middle)\n\n\(close)"
        default:
            base = "\(hook)\n\n\(middle)\n\n\(close)"
        }

        if dialect == "msa" {
            return base.replacingOccurrences(of: "مو ", with: "ليس كل ").replacingOccurrences(of: "وش ", with: "ما ")
        }
        return base
    }

    static func shouldReplace(_ text: String, provider: String, topic: String) -> Bool {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.count < 90 { return true }
        let p = provider.lowercased()
        if p.contains("fallback") || p.contains("local") { return true }
        let weak = ["الفكرة بسيطة", "مشكلة واضحة", "جربها بهذه الصيغة", "حل مباشر", "دعوة بسيطة للتفاعل"]
        if weak.contains(where: { t.contains($0) }) { return true }
        let normalizedTopic = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        if !normalizedTopic.isEmpty && t.components(separatedBy: normalizedTopic).count > 2 { return true }
        return false
    }
}

@MainActor
final class StudioViewModel: ObservableObject {
    @Published var topic = ""
    @Published var brand = ""
    @Published var contentType = "tweets"
    @Published var dialect = "gulf"
    @Published var tone = "friendly"
    @Published var result = ""
    @Published var provider = ""
    @Published var error = ""
    @Published var isLoading = false
    @Published var history: [HistoryItem] = []
    @Published var serverURL = UserDefaults.standard.string(forKey: "serverURL") ?? ""

    init() { loadHistory() }

    func generate() async {
        let cleanTopic = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanTopic.count >= 3 else { return }
        isLoading = true
        error = ""

        do {
            let r = try await APIClient.shared.generate(
                .init(topic: cleanTopic, brand: brand, contentType: contentType, dialect: dialect, tone: tone),
                customBaseURL: serverURL
            )
            let serverText = r.text ?? ""
            let serverProvider = r.provider ?? "AI"
            if CreativeWriter.shouldReplace(serverText, provider: serverProvider, topic: cleanTopic) {
                result = CreativeWriter.compose(topic: cleanTopic, type: contentType, dialect: dialect, tone: tone)
                provider = "Sard Creative"
            } else {
                result = serverText
                provider = serverProvider
            }
        } catch {
            result = CreativeWriter.compose(topic: cleanTopic, type: contentType, dialect: dialect, tone: tone)
            provider = "Sard Creative"
        }

        if !result.isEmpty {
            history.insert(.init(id: UUID(), createdAt: Date(), topic: cleanTopic, text: result, type: contentType), at: 0)
            if history.count > 30 { history.removeLast(history.count - 30) }
            saveHistory()
        }
        isLoading = false
    }

    func regenerate() async { await generate() }
    func saveServerURL() { UserDefaults.standard.set(serverURL, forKey: "serverURL") }
    func clearHistory() { history = []; saveHistory() }

    private func saveHistory() {
        if let data = try? JSONEncoder().encode(history) { UserDefaults.standard.set(data, forKey: "history") }
    }

    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: "history"),
           let items = try? JSONDecoder().decode([HistoryItem].self, from: data) { history = items }
    }
}
