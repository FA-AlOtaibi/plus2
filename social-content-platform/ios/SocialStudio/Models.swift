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
        let isOffer = lower.contains("ريال") || lower.contains("مجاني") || lower.contains("توصيل") || lower.contains("عرض") || lower.contains("خصم") || lower.contains("هدية") || lower.contains("كيلو") || lower.contains("علبة") || lower.contains("اطلب")
        let isApp = lower.contains("تطبيق") || lower.contains("موقع") || lower.contains("منصة")
        let isWriting = lower.contains("فكرة") || lower.contains("سرد") || lower.contains("كتابة") || lower.contains("محتوى") || lower.contains("صياغ")

        var text: String
        if isOffer {
            text = offerCopy(from: clean, variant: variant)
        } else if isApp && isWriting {
            text = appCopy(from: clean, variant: variant)
        } else {
            text = generalCopy(from: clean, variant: variant)
        }

        if type == "thread" {
            let parts = text.components(separatedBy: "\n\n").filter { !$0.isEmpty }
            return parts.enumerated().map { "\($0.offset + 1)/ \($0.element)" }.joined(separator: "\n\n")
        }
        if type == "linkedin" {
            return text + "\n\nوش الزاوية اللي تشوفها أقوى؟"
        }
        return text
    }

    private static func offerCopy(from input: String, variant: Int) -> String {
        let lower = input.lowercased()
        let product = detectProduct(lower)
        let price = firstMatch(in: input, pattern: #"\d+(?:[\.,]\d+)?\s*(?:ريال|ر\.س)"#)
        let quantity = firstMatch(in: input, pattern: #"(?:العلبة\s*)?(?:كيلو|\d+(?:[\.,]\d+)?\s*(?:كيلو|كجم|جرام))"#)
        let hasGift = lower.contains("هدية") || lower.contains("للوالد") || lower.contains("للوالدة")
        let hasMorning = lower.contains("الصباح") || lower.contains("دوام") || lower.contains("صباح")
        let freeDelivery = lower.contains("التوصيل") && lower.contains("مجاني")
        let allCities = lower.contains("كل المدن") || lower.contains("جميع المدن")

        let priceLine = makePriceLine(product: product, price: price, quantity: quantity)
        let delivery = freeDelivery ? (allCities ? "والتوصيل اليوم مجاني لكل المدن." : "والتوصيل اليوم مجاني.") : "والطلب بسيط وما يحتاج تعقيد."

        let angle = abs(variant) % 12
        switch angle {
        case 0:
            return "مو كل هدية لازم تكون رسمية أو مكلفة. أحياناً أفضل هدية هي شيء الشخص فعلاً بيستخدمه.\n\n\(priceLine) \(hasGift ? "مناسب كهدية للوالد،" : "") \(hasMorning ? "وبرضه ينفع يكون جزء من صباحك قبل الدوام." : "")\n\n\(delivery)\n\nإذا ودك به، أرسل مدينتك ونرتبها لك."
        case 1:
            return "لو بتشتري شيء واحد يخدم غرضين، خله شيء ينفع لك وينفع هدية.\n\n\(priceLine)\n\n\(hasGift ? "خذه للوالد بهدية بسيطة ولها قيمة،" : "خذه لك،") \(hasMorning ? "أو خلّه من الأشياء اللي تبدأ فيها صباحك." : "")\n\n\(delivery)"
        case 2:
            return "اليوم العرض بسيط وواضح: \(priceLine)\n\nما فيه لف ولا شروط كثيرة. \(hasGift ? "ينفع هدية،" : "") \(hasMorning ? "وينفع لك مع صباحات الدوام،" : "") وكل التفاصيل الأساسية قدامك.\n\n\(delivery)\n\nللطلب، أرسل مدينتك."
        case 3:
            return "فكرة هدية ما تحتاج تفكير كثير؟\n\n\(priceLine)\n\n\(hasGift ? "خذه للوالد بدل الهدايا المعتادة،" : "") \(hasMorning ? "أو خله لك في البيت لصباحاتك." : "")\n\nوالميزة اليوم: \(freeDelivery ? "التوصيل علينا" : "الطلب سريع").\n\n\(allCities ? "لكل المدن." : "")"
        case 4:
            return "مو لازم نبالغ في الكلام إذا العرض نفسه واضح.\n\n\(priceLine)\n\n\(hasGift ? "هدية عملية للوالد،" : "") \(hasMorning ? "واستخدام يومي لك في الصباح." : "")\n\n\(delivery)"
        case 5:
            return "إذا كنت كل مرة تحتار وش تهدي، هذي من الأشياء اللي ما تحتاج مناسبة كبيرة.\n\n\(priceLine)\n\n\(hasGift ? "تصلح للوالد،" : "") \(hasMorning ? "وتصلح لك بعد كجزء من روتين الصباح." : "")\n\n\(delivery)\n\nاليوم مناسبة إنك تطلبها بدون زيادة شحن."
        case 6:
            return "ثلاث أشياء تخلي العرض يستاهل الالتفات: الكمية واضحة، السعر واضح، والتوصيل اليوم مجاني.\n\n\(priceLine)\n\n\(hasGift ? "خذه هدية للوالد" : "خذه لك")\(hasMorning ? "، أو خله معك لصباحات الدوام" : "").\n\n\(delivery)"
        case 7:
            return "بدل ما تقول: «وش أجيب هدية؟» خل الهدية تكون شيء له استخدام فعلي.\n\n\(priceLine)\n\n\(hasGift ? "للـوالد؟ مناسب." : "") \(hasMorning ? "لك أنت؟ ينفع مع صباحك." : "")\n\n\(delivery)\n\nبكذا أنت ما اشتريت مجرد علبة؛ أخذت شيء له مكان فعلي في اليوم."
        case 8:
            return "يمكن أكثر شيء مغري في العرض مو السعر لحاله، بل إنك تعرف بالضبط وش تاخذ وشلون توصلك.\n\n\(priceLine)\n\n\(hasGift ? "تقدر تخليها هدية للوالد،" : "") \(hasMorning ? "أو تستخدمها أنت في الصباح قبل دوامك." : "")\n\n\(delivery)"
        case 9:
            return "هذا عرض للي يحب الأمور المباشرة:\n\n\(priceLine)\n\n\(hasGift ? "هدية مناسبة للوالد." : "")\n\(hasMorning ? "ومناسبة لك إذا تبي شيء يدخل ضمن روتينك الصباحي." : "")\n\n\(delivery)\n\nأرسل مدينتك ونكمل الطلب."
        case 10:
            return "أحياناً أفضل قرار شراء هو اللي ما يحتاج مقارنة طويلة.\n\n\(priceLine)\n\n\(hasGift ? "خذه هدية وريح نفسك من الحيرة،" : "") \(hasMorning ? "أو احتفظ فيه لك للصباح." : "")\n\n\(delivery)\n\nاليوم أنت تدفع للمنتج فقط، مو للشحن."
        default:
            return "وش أحسن من هدية تستخدم؟ هدية تستخدم وتوصلك بدون رسوم شحن.\n\n\(priceLine)\n\n\(hasGift ? "مناسبة للوالد،" : "") \(hasMorning ? "ومناسبة لك مع بداية اليوم." : "")\n\n\(delivery)\n\nإذا عجبتك الفكرة، أرسل مدينتك وخلاص."
        }
    }

    private static func appCopy(from input: String, variant: Int) -> String {
        let variants = [
            "المشكلة مو إن الناس ما عندها أفكار؛ المشكلة إن الفكرة وهي في الرأس تكون أوضح من لحظة كتابتها.\n\n\(input)\n\nهنا قيمة التطبيق: يأخذ الكلام الخام، يكتشف المقصد، ويحوّله إلى نص له زاوية وإيقاع بدون ما يحوله إلى كلام روبوتي.",
            "تكتبها بطريقتك، حتى لو كانت ناقصة أو مبعثرة. التطبيق ما يعيد ترتيب الكلمات فقط؛ يقرر وش المهم، وش اللي يحتاج توضيح، وش اللي ممكن يتحول إلى افتتاحية أقوى.\n\n\(input)\n\nالنتيجة: نص يشبه الفكرة قبل ما تضيع في الصياغة.",
            "مو محتاج محرر نصوص ثاني. محتاج محرر يفهمك قبل ما يكتب لك.\n\n\(input)\n\nالفكرة هنا إنك تعطيه الشرارة، وهو يبني حولها بنية كاملة: بداية، معنى، زاوية، ثم نهاية تليق بالسياق.",
            "فيه فرق بين أداة تقول لك نفس الجملة بطريقة أفخم، وأداة فعلاً تستنبط من اللي كتبته.\n\n\(input)\n\nسرد المفروض يشتغل على الثاني: يلتقط الفكرة، يوسّعها، ويطلع منها نسخة قابلة للنشر أو التعديل بدون ما يحبس المستخدم في قالب واحد."
        ]
        return variants[abs(variant) % variants.count]
    }

    private static func generalCopy(from input: String, variant: Int) -> String {
        let variants = [
            "\(input)\n\nالزاوية الأقوى هنا مو إعادة الكلام، بل توضيح ليش هذه الفكرة تستحق الانتباه وش اللي يتغير بسببها.",
            "خل الفكرة تمشي من السبب إلى النتيجة:\n\n\(input)\n\nإذا عرف القارئ من أول سطر ليش يهمه الموضوع، باقي النص يصير أسهل وأقوى.",
            "النص الجيد ما يشرح الفكرة فقط؛ يعطيها موقف وصوت.\n\n\(input)\n\nخلنا نبني حول الشيء اللي يخليها مختلفة، مو حول تعريفها فقط.",
            "أحياناً أقوى نسخة للفكرة تبدأ بسؤال واحد: وش الشيء اللي يهم الشخص فعلاً هنا؟\n\n\(input)\n\nلما تجاوب هذا السؤال، الصياغة تتحول من وصف إلى رسالة."
        ]
        return variants[abs(variant) % variants.count]
    }

    private static func detectProduct(_ lower: String) -> String {
        if lower.contains("عسل") && lower.contains("سدر") { return "عسل سدر" }
        if lower.contains("عسل") { return "العسل" }
        if lower.contains("قهوة") { return "القهوة" }
        if lower.contains("عطر") { return "العطر" }
        if lower.contains("تمر") { return "التمر" }
        return "المنتج"
    }

    private static func makePriceLine(product: String, price: String?, quantity: String?) -> String {
        if let price, let quantity { return "\(product)، \(quantity) بـ \(price)." }
        if let price { return "\(product) بـ \(price)." }
        if let quantity { return "\(product)، \(quantity)." }
        return product + "."
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
        variant = Int.random(in: 0..<10000)
        await runGeneration()
    }

    func regenerate() async {
        variant += Int.random(in: 1...97)
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
                provider = "Sard Creative 3"
            } else {
                result = serverText
                provider = serverProvider
            }
        } catch {
            result = CreativeWriter.compose(topic: cleanTopic, type: contentType, dialect: dialect, tone: tone, variant: variant)
            provider = "Sard Creative 3"
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
