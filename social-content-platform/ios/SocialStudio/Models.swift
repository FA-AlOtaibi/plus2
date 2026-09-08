import Foundation

struct HistoryItem: Identifiable, Codable {
    let id: UUID
    let createdAt: Date
    let topic: String
    let text: String
    let type: String
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

    private var sessionDrafts: [String] = []
    private var sessionTopic = ""

    init() { loadHistory() }

    func generate() async {
        let clean = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        guard clean.count >= 3 else { return }
        if clean != sessionTopic {
            sessionTopic = clean
            sessionDrafts = []
        }
        await runGeneration(isRegeneration: false)
    }

    func regenerate() async {
        let clean = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        guard clean.count >= 3 else { return }
        if clean != sessionTopic {
            sessionTopic = clean
            sessionDrafts = []
        }
        if !result.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           !sessionDrafts.contains(result) {
            sessionDrafts.append(result)
        }
        await runGeneration(isRegeneration: true)
    }

    private func runGeneration(isRegeneration: Bool) async {
        let cleanTopic = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        isLoading = true
        error = ""

        let previous = Array(sessionDrafts.suffix(6))
        let memoryBlock: String
        if previous.isEmpty {
            memoryBlock = ""
        } else {
            memoryBlock = """

هذه صياغات سابقة ممنوع تكرارها أو تقليد بنائها أو افتتاحياتها أو CTA الخاص بها:
\(previous.enumerated().map { "[\($0.offset + 1)] \($0.element)" }.joined(separator: "\n---\n"))

في هذه المحاولة اختر زاوية مختلفة جذرياً، وبناء مختلف، وافتتاحية مختلفة، وإيقاع مختلف. لا تستخدم إعادة صياغة سطحية.
"""
        }

        let intelligenceBrief = """
أنت كاتب إبداعي عربي محترف جداً. لا تعِد كلام المستخدم ولا تشرح له فكرته. افهم المدخلات، استنبط منها الزوايا والقيمة والسياق والجمهور المحتمل، ثم اكتب نصاً يبدو من كاتب بشري ذكي.

قواعد صارمة:
- لا تخترع سعراً أو خصماً أو كمية أو وعداً أو معلومة واقعية غير موجودة.
- مسموح بالاستنباط الإبداعي من المعلومات الموجودة: مناسبة، شعور، استخدام، زاوية تسويقية، مقارنة معنوية، قصة قصيرة، سؤال، مفارقة، Hook، CTA مناسب.
- كل مرة يجب أن تكون الصياغة جديدة فعلاً، لا تبديل مرادفات.
- تجنب القوالب المحفوظة مثل: «الفكرة بسيطة»، «المشكلة والحل»، «ثلاث أشياء»، «مو لازم العرض يصرخ» إلا إذا جاءت طبيعياً وكانت مختلفة عن السابق.
- لا تقل للمستخدم ما الذي فعلته. أعطه النص النهائي فقط.
- حافظ على اللهجة والنبرة والنوع المطلوب.
- إذا كانت تغريدة فاجعلها مركزة وقابلة للنشر، لا مقالاً طويلاً.
- إذا كان إعلاناً فليكن مقنعاً وذا CTA طبيعي غير مبتذل.
- إذا كان ثريداً فاجعل كل جزء يضيف فكرة جديدة.
- إذا كان LinkedIn فاجعله أعمق وأكثر مهنية.

\(isRegeneration ? "هذه إعادة توليد: ابتعد قدر الإمكان عن أي صياغة سابقة." : "هذه أول صياغة: اختر أفضل زاوية من المدخلات نفسها.")
"""

        let combinedBrand = [brand.trimmingCharacters(in: .whitespacesAndNewlines), intelligenceBrief, memoryBlock]
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")

        do {
            let response = try await APIClient.shared.generate(
                .init(topic: cleanTopic, brand: combinedBrand, contentType: contentType, dialect: dialect, tone: tone),
                customBaseURL: serverURL
            )

            let text = (response.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let source = (response.provider ?? "AI").trimmingCharacters(in: .whitespacesAndNewlines)
            let sourceLower = source.lowercased()

            guard !text.isEmpty else {
                throw APIError.server("النموذج رجع نتيجة فارغة. حاول مرة ثانية.")
            }
            guard !sourceLower.contains("fallback") && !sourceLower.contains("local") && !sourceLower.contains("sard creative") else {
                throw APIError.server("محرك الذكاء الاصطناعي الحقيقي غير متاح حالياً. تأكد من HF_TOKEN ثم حاول مرة أخرى.")
            }

            result = text
            provider = source
            if !sessionDrafts.contains(text) { sessionDrafts.append(text) }

            history.insert(.init(id: UUID(), createdAt: Date(), topic: cleanTopic, text: text, type: contentType), at: 0)
            if history.count > 30 { history.removeLast(history.count - 30) }
            saveHistory()
        } catch {
            result = ""
            provider = ""
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func saveServerURL() { UserDefaults.standard.set(serverURL, forKey: "serverURL") }
    func clearHistory() { history = []; saveHistory() }

    private func saveHistory() {
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: "history")
        }
    }

    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: "history"),
           let items = try? JSONDecoder().decode([HistoryItem].self, from: data) {
            history = items
        }
    }
}
