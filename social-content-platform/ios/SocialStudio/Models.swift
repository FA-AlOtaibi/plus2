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
    @Published var tone = "custom"
    @Published var styleGuide = UserDefaults.standard.string(forKey: "styleGuide") ?? ""
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
        let cleanStyle = styleGuide.trimmingCharacters(in: .whitespacesAndNewlines)
        isLoading = true
        error = ""

        let previous = Array(sessionDrafts.suffix(8))
        let memory = previous.isEmpty ? "" : """
هذه نصوص خرجت سابقاً لنفس الفكرة. لا تكرر افتتاحيتها أو ترتيبها أو جملها أو خاتمتها:
\(previous.enumerated().map { "[\($0.offset + 1)] \($0.element)" }.joined(separator: "\n---\n"))
"""

        let styleInstruction = cleanStyle.isEmpty
            ? "اكتب بأسلوب طبيعي جداً، واضح، قصير، وكأنه من شخص حقيقي. لا تتفلسف ولا تضف قصة من عندك."
            : "أسلوب الكتابة الذي طلبه المستخدم حرفياً، وهو أولوية عالية: \(cleanStyle)"

        let instruction = """
\(styleInstruction)

تعليمات جودة ثابتة:
- حافظ على الحقائق الموجودة في الفكرة كما هي، ولا تضف فائدة أو تجربة أو قصة أو صفة غير مذكورة.
- مسموح لك أن تحسن الترتيب والافتتاحية والإيقاع والوضوح فقط، ما لم يطلب المستخدم صراحة الاستنباط أو السرد أو الابتكار في خانة الأسلوب.
- لا تستخدم جمل شاعرية أو عاطفية من عندك إلا إذا طلبها المستخدم في أسلوبه.
- لا تجعل النص يبدو كإعلان مولد بالذكاء الاصطناعي.
- إذا كانت الصيغة تغريدة، اكتب نصاً واحداً صالحاً للنشر ومركزاً.
\(isRegeneration ? "هذه صياغة جديدة: غير المدخل والبناء فعلاً مع الالتزام بنفس أسلوب المستخدم." : "هذه أول صياغة.")
\(memory)
\(brand)
"""

        do {
            let response: GenerateResponse
            let directKey = hfToken.trimmingCharacters(in: .whitespacesAndNewlines)
            if !directKey.isEmpty {
                response = try await generateDistinctHF(
                    key: directKey,
                    topic: cleanTopic,
                    instruction: instruction,
                    previous: previous,
                    style: cleanStyle
                )
            } else {
                let serverResponse = try await APIClient.shared.generate(
                    .init(topic: cleanTopic, brand: instruction, contentType: contentType, dialect: dialect, tone: "custom"),
                    customBaseURL: serverURL
                )
                let source = (serverResponse.provider ?? "").lowercased()
                if source.contains("grounded") || source.contains("fallback") || source.contains("local") || source.contains("creative") {
                    throw APIError.server("الخادم يستخدم محركاً احتياطياً. أدخل HF Token من الإعدادات لاستخدام النموذج الحقيقي.")
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

    private func generateDistinctHF(key: String, topic: String, instruction: String, previous: [String], style: String) async throws -> GenerateResponse {
        var last: GenerateResponse?
        var extra = ""
        for attempt in 0..<3 {
            let requestedStyle = style.isEmpty ? "طبيعي، واضح، بشري، بدون مبالغة" : style
            let r = try await APIClient.shared.generateWithHuggingFace(
                token: key,
                topic: topic,
                instruction: instruction,
                contentType: contentType,
                dialect: dialect,
                tone: requestedStyle,
                extraAvoidance: extra
            )
            last = r
            let candidate = r.text ?? ""
            let maxSimilarity = previous.map { similarity(candidate, $0) }.max() ?? 0
            if previous.isEmpty || maxSimilarity < 0.44 { return r }
            extra = "الصياغة قريبة من نص سابق. أعد الكتابة من مدخل مختلف تماماً، لكن لا تغير الحقائق ولا تخالف أسلوب المستخدم. هذه محاولة رقم \(attempt + 2)."
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
        UserDefaults.standard.set(styleGuide, forKey: "styleGuide")
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
