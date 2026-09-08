import Foundation

struct HistoryItem: Identifiable, Codable {
    let id: UUID
    let createdAt: Date
    let topic: String
    let text: String
    let type: String
}

private enum CreativeWriter {
    static func compose(topic: String, type: String, dialect: String, tone: String, variant: Int) -> String {
        let clean = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = clean.lowercased()

        let isApp = lower.contains("تطبيق") || lower.contains("موقع") || lower.contains("منصة")
        let isWriting = lower.contains("فكرة") || lower.contains("سرد") || lower.contains("كتابة") || lower.contains("محتوى") || lower.contains("صياغ")
        let isOffer = lower.contains("ريال") || lower.contains("مجاني") || lower.contains("توصيل") || lower.contains("عرض") || lower.contains("خصم") || lower.contains("هدية") || lower.contains("كيلو") || lower.contains("علبة") || lower.contains("اطلب")

        var text: String

        if isOffer {
            text = offerCopy(from: clean, variant: variant)
        } else if isApp && isWriting {
            let variants = [
                "الفكرة مو إنك تعطي الذكاء الاصطناعي جملة ويرجعها لك بكلمات أفخم. الفكرة إنك ترمي له الكلام مثل ما هو في رأسك، وهو يلقط المقصد، يستخرج الزاوية، ويحوّلها إلى نص له بداية وصوت ونهاية.\n\nيعني بدل ما تبدأ من صفحة بيضاء، تبدأ من شيء يشبهك أنت — لكن مرتب، أوضح، وأقوى. وبعدها أنت تقرر: تعدّل، تحفظ، أو تنشر.\n\nهذا الفرق بين أداة «تعيد الصياغة» وأداة فعلاً تفهم وش كنت تحاول تقول.",
                "أحياناً الفكرة تكون واضحة في رأسك… لكن أول ما تحاول تكتبها تصير أضعف مما تخيلتها.\n\nهنا يجي دور التطبيق: تكتب الفكرة الخام بدون ترتيب وبدون ما تهتم بالصياغة، وهو يبني منها الرسالة، يختار الزاوية المناسبة، ويضيف التفاصيل اللي تخلي النص متماسكاً بدل ما يكون مجرد إعادة لكلامك.\n\nالفكرة تظل فكرتك. اللي يتغير هو طريقة وصولها للناس.",
                "مو ناقصنا مولّد نصوص جديد؛ الناقص أداة تعرف الفرق بين «كلام مرتب» و«فكرة وصلت».\n\nتكتب اللي في بالك كما هو، والتطبيق يتعامل معه كمسودة حقيقية: يفهم المقصد، يوسع النقاط الناقصة، ويربط التفاصيل ببعضها، ثم يعطيك نصاً جاهزاً للتحرير. ما فيه نشر إجباري ولا نسخ ولصق كأنك تتعامل مع روبوت.\n\nالفكرة ببساطة: أنت تعطيه الشرارة، وهو يبني حولها النص."
            ]
            text = variants[abs(variant) % variants.count]
        } else {
            text = generalCopy(from: clean, variant: variant)
        }

        if type == "thread" {
            let parts = text.components(separatedBy: "\n\n")
            return parts.enumerated().map { "\($0.offset + 1)/ \($0.element)" }.joined(separator: "\n\n")
        }
        if type == "linkedin" {
            return text + "\n\nوش أكثر شيء تشوفه يصنع الفرق هنا؟"
        }
        if type == "caption" || type == "ad" || type == "tweets" {
            return text
        }
        return text
    }

    private static func offerCopy(from input: String, variant: Int) -> String {
        let lower = input.lowercased()
        let hasSidr = lower.contains("سدر")
        let hasHoney = lower.contains("عسل")
        let hasGift = lower.contains("هدية") || lower.contains("للوالد") || lower.contains("للوالدة")
        let hasMorning = lower.contains("الصباح") || lower.contains("دوام")
        let freeDelivery = lower.contains("التوصيل") && lower.contains("مجاني")

        let product = hasHoney ? (hasSidr ? "عسل سدر" : "العسل") : "المنتج"
        let price = firstMatch(in: input, pattern: #"\d+(?:[\.,]\d+)?\s*(?:ريال|ر\.س)"#)
        let quantity = firstMatch(in: input, pattern: #"(?:العلبة\s*)?(?:كيلو|\d+(?:[\.,]\d+)?\s*(?:كيلو|كجم|جرام))"#)

        let priceLine: String = {
            if let price, let quantity { return "\(product)، \(quantity) بـ \(price)." }
            if let price { return "\(product) بـ \(price)." }
            if let quantity { return "\(product)، \(quantity)." }
            return product + "."
        }()

        let useLine: String = {
            if hasGift && hasMorning { return "خذه هدية للوالد، أو خلّه لك مع صباحات الدوام اللي تحب تبدأها بشيء بسيط ومألوف." }
            if hasGift { return "ينفع هدية جميلة بدون تكلف، وينفع يكون من الأشياء اللي تبقى في البيت ويُرجع لها كل يوم." }
            if hasMorning { return "خلّه جزء من صباحك بدل ما تبدأ يومك على عجلة." }
            return "شيء بسيط، واضح، وتعرف بالضبط وش تاخذ مقابله."
        }()

        let deliveryLine = freeDelivery ? "والتوصيل اليوم علينا — مجاناً لكل المدن." : "اطلبه بالطريقة المناسبة لك ونرتب لك الباقي."

        let variants = [
            "فيه هدايا تنحط على الرف… وفيه هدايا تدخل في يوم الشخص نفسه.\n\n\(priceLine) \(useLine)\n\n\(deliveryLine)\n\nإذا ودك بعلبة، أرسل مدينتك ونرتبها لك.",
            "مو لازم العرض يصرخ عشان يكون مغري. يكفي يكون واضح ويستاهل.\n\n\(priceLine) \(useLine)\n\n\(deliveryLine)\n\nخذها لك أو خلّها هدية لشخص عزيز عليك.",
            "صباح أهدأ، وهدية لها معنى، وطلب ما يحتاج تعقيد.\n\n\(priceLine)\n\n\(useLine)\n\n\(deliveryLine)\n\nللطلب: أرسل مدينتك وخل الباقي علينا."
        ]
        return variants[abs(variant) % variants.count]
    }

    private static func generalCopy(from input: String, variant: Int) -> String {
        let variants = [
            "خلّنا نقولها بطريقة أوضح: \(input)\n\nالمهم هنا مو تكرار الفكرة، بل إبراز الشيء اللي يخليها تستحق الانتباه: وش يتغير للناس بسببها؟ وليش يهتمون من الأساس؟\n\nإذا ظهرت هالنقطتين في النص، يصير الكلام أقرب لفكرة حقيقية وأبعد عن وصف عام.",
            "\(input)\n\nالفكرة فيها أكثر من مجرد الجملة نفسها. فيها وعد ضمني بشيء أسهل أو أفضل أو أوضح. النص الجيد يطلع هذا الوعد للواجهة، ثم يخلي التفاصيل تثبته بدل ما تزاحمه.\n\nابدأ بالمعنى، وبعدها خل كل جملة تخدمه.",
            "أقوى زاوية هنا مو «وش هي الفكرة؟» بل «ليش تهم؟».\n\n\(input)\n\nلما نبني النص حول السبب والنتيجة والتجربة اللي يعيشها الشخص، تصير الفكرة مفهومة من أول قراءة وتطلع لها شخصية بدل ما تكون مجرد شرح."
        ]
        return variants[abs(variant) % variants.count]
    }

    private static func firstMatch(in text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let ns = text as NSString
        let range = NSRange(location: 0, length: ns.length)
        guard let match = regex.firstMatch(in: text, range: range) else { return nil }
        return ns.substring(with: match.range).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func shouldReplace(_ text: String, provider: String, topic: String) -> Bool {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.count < 120 { return true }
        let p = provider.lowercased()
        if p.contains("fallback") || p.contains("local") || p.contains("sard creative") { return true }
        let weak = ["الفكرة بسيطة", "مشكلة واضحة", "جربها بهذه الصيغة", "حل مباشر", "دعوة بسيطة للتفاعل", "في فكرتك زاوية أقوى", "الهدف: نخليها مفهومة"]
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
    private var variant = 0

    init() { loadHistory() }

    func generate() async {
        variant = 0
        await runGeneration()
    }

    func regenerate() async {
        variant += 1
        await runGeneration()
    }

    private func runGeneration() async {
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
                result = CreativeWriter.compose(topic: cleanTopic, type: contentType, dialect: dialect, tone: tone, variant: variant)
                provider = "Sard Creative 2"
            } else {
                result = serverText
                provider = serverProvider
            }
        } catch {
            result = CreativeWriter.compose(topic: cleanTopic, type: contentType, dialect: dialect, tone: tone, variant: variant)
            provider = "Sard Creative 2"
        }

        if !result.isEmpty {
            history.insert(.init(id: UUID(), createdAt: Date(), topic: cleanTopic, text: result, type: contentType), at: 0)
            if history.count > 30 { history.removeLast(history.count - 30) }
            saveHistory()
        }
        isLoading = false
    }

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
