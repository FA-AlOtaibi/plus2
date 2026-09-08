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
    @Published var hfToken = SecureStore.loadHFToken()

    private var sessionDrafts: [String] = []
    private var sessionTopic = ""

    init() { loadHistory() }

    func generate() async {
        let clean = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        guard clean.count >= 3 else { return }
        if clean != sessionTopic { sessionTopic = clean; sessionDrafts = [] }
        await runGeneration(isRegeneration: false)
    }

    func regenerate() async {
        let clean = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        guard clean.count >= 3 else { return }
        if clean != sessionTopic { sessionTopic = clean; sessionDrafts = [] }
        if !result.isEmpty && !sessionDrafts.contains(result) { sessionDrafts.append(result) }
        await runGeneration(isRegeneration: true)
    }

    private func runGeneration(isRegeneration: Bool) async {
        let cleanTopic = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        isLoading = true
        error = ""

        let previous = Array(sessionDrafts.suffix(8))
        let memory = previous.isEmpty ? "" : """
نصوص سابقة ممنوع تكرار فكرتها أو افتتاحيتها أو ترتيبها أو CTA الخاص بها:
\(previous.enumerated().map { "[\($0.offset + 1)] \($0.element)" }.joined(separator: "\n---\n"))
"""
        let instruction = """
تعامل مع الفكرة كمدير إبداعي، لا كأداة إعادة صياغة. استنبط الجمهور والمناسبة والدافع والاستخدام والشعور والقيمة، ثم ابنِ نصاً جديداً من الصفر. لا تضف حقائق أو أرقاماً غير موجودة.
\(isRegeneration ? "هذه إعادة توليد: غيّر الزاوية والبناء والافتتاحية والنهاية جذرياً." : "هذه أول محاولة: اختر أقوى زاوية بشرية وغير متوقعة.")
\(memory)
\(brand)
"""

        do {
            let response: GenerateResponse
            let directKey = hfToken.trimmingCharacters(in: .whitespacesAndNewlines)
            if !directKey.isEmpty {
                response = try await generateDistinctHF(key: directKey, topic: cleanTopic, instruction: instruction, previous: previous)
            } else {
                let serverResponse = try await APIClient.shared.generate(
                    .init(topic: cleanTopic, brand: instruction, contentType: contentType, dialect: dialect, tone: tone),
                    customBaseURL: serverURL
                )
                let source = (serverResponse.provider ?? "").lowercased()
                if source.contains("grounded") || source.contains("fallback") || source.contains("local") || source.contains("creative") {
                    throw APIError.server("الخادم ما زال يستخدم المحرك الاحتياطي. افتح الإعدادات وأدخل HF Token ليستخدم Qwen مباشرة.")
                }
                response = serverResponse
            }

            let text = (response.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { throw APIError.server("النموذج رجع نتيجة فارغة.") }
            result = text
            provider = response.provider ?? "AI"
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

    private func generateDistinctHF(key: String, topic: String, instruction: String, previous: [String]) async throws -> GenerateResponse {
        var last: GenerateResponse?
        var extra = ""
        for attempt in 0..<3 {
            let r = try await APIClient.shared.generateWithHuggingFace(
                token: key,
                topic: topic,
                instruction: instruction,
                contentType: contentType,
                dialect: dialect,
                tone: tone,
                extraAvoidance: extra
            )
            last = r
            let candidate = r.text ?? ""
            let maxSimilarity = previous.map { similarity(candidate, $0) }.max() ?? 0
            if previous.isEmpty || maxSimilarity < 0.48 { return r }
            extra = "المحاولة السابقة تشبه نصاً سابقاً. في المحاولة رقم \(attempt + 2) غيّر الفكرة الكتابية نفسها، لا المرادفات فقط: Hook آخر، مشهد آخر، دافع آخر، وبنية وخاتمة مختلفتان تماماً."
        }
        return last ?? GenerateResponse(text: nil, provider: nil, error: "تعذر التوليد")
    }

    private func similarity(_ a: String, _ b: String) -> Double {
        let wa = words(a), wb = words(b)
        guard !wa.isEmpty, !wb.isEmpty else { return 0 }
        let sa = Set(wa), sb = Set(wb)
        let wordUnion = sa.union(sb).count
        let wordScore = wordUnion == 0 ? 0 : Double(sa.intersection(sb).count) / Double(wordUnion)
        let ba = Set(bigrams(wa)), bb = Set(bigrams(wb))
        let biUnion = ba.union(bb).count
        let biScore = biUnion == 0 ? 0 : Double(ba.intersection(bb).count) / Double(biUnion)
        return wordScore * 0.45 + biScore * 0.55
    }

    private func words(_ text: String) -> [String] {
        text.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted).filter { $0.count > 1 }
    }

    private func bigrams(_ w: [String]) -> [String] {
        guard w.count > 1 else { return [] }
        return (0..<(w.count - 1)).map { w[$0] + "|" + w[$0 + 1] }
    }

    func saveSettings() {
        UserDefaults.standard.set(serverURL, forKey: "serverURL")
        SecureStore.saveHFToken(hfToken)
        hfToken = SecureStore.loadHFToken()
    }

    func saveServerURL() { saveSettings() }
    func clearHistory() { history = []; saveHistory() }

    private func saveHistory() {
        if let data = try? JSONEncoder().encode(history) { UserDefaults.standard.set(data, forKey: "history") }
    }

    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: "history"),
           let items = try? JSONDecoder().decode([HistoryItem].self, from: data) { history = items }
    }
}
