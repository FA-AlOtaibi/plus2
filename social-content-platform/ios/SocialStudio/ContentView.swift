import SwiftUI

struct ContentView: View {
    @StateObject private var vm = StudioViewModel()
    @State private var showSettings = false
    @State private var showHistory = false
    @State private var showShare = false
    @State private var showPublishMenu = false
    @State private var appeared = false
    @State private var pulse = false
    @State private var resultAppeared = false
    @FocusState private var focus: Field?

    private enum Field { case idea, style }

    private let canvas = Color(red: 0.973, green: 0.969, blue: 0.956)
    private let ink = Color(red: 0.055, green: 0.055, blue: 0.06)
    private let accent = Color(red: 0.94, green: 0.27, blue: 0.12)
    private let mist = Color(red: 0.91, green: 0.92, blue: 0.89)

    var body: some View {
        NavigationStack {
            ZStack {
                canvas.ignoresSafeArea()
                ambientBackground

                ScrollView {
                    VStack(spacing: 18) {
                        header
                            .modifier(Entrance(active: appeared, delay: 0.00, y: -18))
                        hero
                            .modifier(Entrance(active: appeared, delay: 0.08, y: 24))
                        composer
                            .modifier(Entrance(active: appeared, delay: 0.16, y: 34))

                        if vm.isLoading {
                            thinking
                                .transition(.scale(scale: 0.92).combined(with: .opacity).combined(with: .move(edge: .bottom)))
                        }

                        if !vm.result.isEmpty || !vm.error.isEmpty {
                            resultCard
                                .transition(.move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.96)))
                        }

                        Spacer(minLength: 52)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showSettings) { SettingsView(vm: vm) }
            .sheet(isPresented: $showHistory) { HistoryView(vm: vm) }
            .sheet(isPresented: $showShare) { ShareSheet(items: [vm.result]) }
            .confirmationDialog("انشر في", isPresented: $showPublishMenu, titleVisibility: .visible) {
                Button("X") { publish(to: "x") }
                Button("واتساب") { publish(to: "whatsapp") }
                Button("تيليجرام") { publish(to: "telegram") }
                Button("مشاركة عبر iOS") { showShare = true }
                Button("إلغاء", role: .cancel) {}
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .tint(accent)
        .onAppear {
            pulse = true
            withAnimation(.spring(response: 0.72, dampingFraction: 0.84)) { appeared = true }
        }
        .onChange(of: vm.result) { _, newValue in
            guard !newValue.isEmpty else { return }
            resultAppeared = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.spring(response: 0.62, dampingFraction: 0.80)) { resultAppeared = true }
            }
        }
    }

    private var ambientBackground: some View {
        ZStack {
            Circle()
                .fill(accent.opacity(0.08))
                .frame(width: 310, height: 310)
                .blur(radius: 18)
                .offset(x: pulse ? 145 : 110, y: pulse ? -270 : -220)
                .animation(.easeInOut(duration: 5).repeatForever(autoreverses: true), value: pulse)

            RoundedRectangle(cornerRadius: 90)
                .fill(Color.black.opacity(0.025))
                .frame(width: 300, height: 440)
                .rotationEffect(.degrees(-18))
                .blur(radius: 8)
                .offset(x: pulse ? -175 : -140, y: pulse ? 380 : 330)
                .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: pulse)
        }
        .allowsHitTesting(false)
    }

    private var header: some View {
        HStack(spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(ink)
                        .frame(width: 46, height: 46)
                    Text("س")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("سرد")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                    Text("WRITE IT YOUR WAY")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .tracking(1.5)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            iconButton("clock.arrow.circlepath") { showHistory = true }
            iconButton("gearshape") { showSettings = true }
        }
    }

    private func iconButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(ink)
                .frame(width: 42, height: 42)
                .background(Color.white.opacity(0.72), in: Circle())
                .overlay(Circle().stroke(Color.black.opacity(0.06), lineWidth: 1))
        }
        .buttonStyle(PressableButtonStyle())
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("أنت تحدد الصوت.")
                .font(.system(size: 42, weight: .black, design: .rounded))
                .minimumScaleFactor(0.75)
            Text("لا نبرة جاهزة ولا قالب محفوظ. اكتب الفكرة، وبعدها اكتب بنفسك كيف تبي النص يطلع — قصير، ساخر، رسمي، نجدي، مباشر، قصصي… أو أي وصف يخطر ببالك.")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)
                .lineSpacing(5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var composer: some View {
        VStack(spacing: 0) {
            ideaSection
            Divider().opacity(0.45).padding(.horizontal, 18)
            styleSection
            controlsSection
        }
        .background(Color.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 30))
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.black.opacity(0.06), lineWidth: 1))
        .shadow(color: .black.opacity(0.05), radius: 24, y: 12)
    }

    private var ideaSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("وش الفكرة؟")
                        .font(.system(size: 19, weight: .bold))
                    Text("اكتب المعلومات مثل ما هي، حتى لو كانت مبعثرة")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("01")
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundStyle(accent)
            }

            ZStack(alignment: .topLeading) {
                TextEditor(text: $vm.topic)
                    .focused($focus, equals: .idea)
                    .scrollContentBackground(.hidden)
                    .font(.system(size: 21, weight: .medium))
                    .lineSpacing(7)
                    .padding(13)
                    .frame(minHeight: 190)
                    .background(mist.opacity(0.46), in: RoundedRectangle(cornerRadius: 22))

                if vm.topic.isEmpty {
                    Text("مثال: عسل سدر، الكيلو 150 ريال، مناسب هدية للوالد، والتوصيل اليوم مجاني…")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(.secondary.opacity(0.68))
                        .padding(18)
                        .allowsHitTesting(false)
                }
            }
        }
        .padding(18)
    }

    private var styleSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("كيف تبي الكلام؟")
                        .font(.system(size: 19, weight: .bold))
                    Text("هذه الخانة هي اللي تتحكم بالأسلوب فعلياً")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("02")
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundStyle(accent)
            }

            ZStack(alignment: .topLeading) {
                TextEditor(text: $vm.styleGuide)
                    .focused($focus, equals: .style)
                    .scrollContentBackground(.hidden)
                    .font(.system(size: 17, weight: .medium))
                    .lineSpacing(5)
                    .padding(12)
                    .frame(minHeight: 118)
                    .background(accent.opacity(0.055), in: RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(accent.opacity(0.15), lineWidth: 1))

                if vm.styleGuide.isEmpty {
                    Text("مثلاً: أبيها خليجية خفيفة، سطرين فقط، بدون إيموجي، ابدأ بالسعر، لا تتفلسف، وختمها بدعوة قصيرة للطلب.")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(.secondary.opacity(0.72))
                        .padding(17)
                        .allowsHitTesting(false)
                }
            }

            Text("اكتب وصفك بحرية. مو لازم تختار من شيء جاهز.")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(accent.opacity(0.85))
        }
        .padding(18)
    }

    private var controlsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 9) {
                formatMenu
                dialectMenu
            }

            Button {
                focus = nil
                UserDefaults.standard.set(vm.styleGuide, forKey: "styleGuide")
                Task { await vm.generate() }
            } label: {
                HStack(spacing: 9) {
                    if vm.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "arrow.down.left")
                    }
                    Text(vm.isLoading ? "جالس يكتب على طريقتك…" : "اكتبها على طريقتي")
                        .font(.system(size: 17, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
            }
            .buttonStyle(PressableButtonStyle())
            .foregroundStyle(.white)
            .background(canGenerate ? ink : Color.gray.opacity(0.5), in: RoundedRectangle(cornerRadius: 18))
            .disabled(!canGenerate || vm.isLoading)
        }
        .padding(18)
        .padding(.top, -4)
    }

    private var thinking: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(accent.opacity(0.12)).frame(width: 42, height: 42)
                HStack(spacing: 3) {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(accent)
                            .frame(width: 5, height: 5)
                            .modifier(BubblePulse(delay: Double(i) * 0.14))
                    }
                }
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("نكتب حسب وصفك")
                    .font(.system(size: 15, weight: .bold))
                Text(vm.styleGuide.isEmpty ? "أسلوب طبيعي وواضح بدون إضافات من عندنا" : shortStylePreview)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.white.opacity(0.76), in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.black.opacity(0.05), lineWidth: 1))
    }

    private var shortStylePreview: String {
        let clean = vm.styleGuide.trimmingCharacters(in: .whitespacesAndNewlines)
        return clean.count > 80 ? String(clean.prefix(80)) + "…" : clean
    }

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("النسخة")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                    if !vm.provider.isEmpty {
                        Text(vm.provider.uppercased())
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .tracking(1.2)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                RoundedRectangle(cornerRadius: 3)
                    .fill(accent)
                    .frame(width: 36, height: 6)
            }

            if !vm.error.isEmpty {
                Text(vm.error)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.red)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
            }

            if !vm.result.isEmpty {
                TextEditor(text: $vm.result)
                    .scrollContentBackground(.hidden)
                    .font(.system(size: 20, weight: .regular))
                    .lineSpacing(7)
                    .frame(minHeight: 250)
                    .padding(13)
                    .background(mist.opacity(0.42), in: RoundedRectangle(cornerRadius: 20))
                    .opacity(resultAppeared ? 1 : 0)
                    .offset(y: resultAppeared ? 0 : 14)

                HStack(spacing: 8) {
                    resultAction("نسخ", "doc.on.doc") { UIPasteboard.general.string = vm.result }
                    resultAction("نسخة جديدة", "arrow.triangle.2.circlepath") { Task { await vm.regenerate() } }
                    resultAction("نشر", "paperplane.fill", filled: true) { showPublishMenu = true }
                }
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 28))
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.black.opacity(0.06), lineWidth: 1))
        .shadow(color: .black.opacity(0.06), radius: 22, y: 10)
    }

    private func resultAction(_ title: String, _ icon: String, filled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                Text(title).lineLimit(1)
            }
            .font(.caption.bold())
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(PressableButtonStyle())
        .foregroundStyle(filled ? .white : ink)
        .background(filled ? accent : mist.opacity(0.65), in: Capsule())
    }

    private var canGenerate: Bool {
        vm.topic.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3
    }

    private var formatMenu: some View {
        Menu {
            Button("تغريدة") { vm.contentType = "tweets" }
            Button("ثريد") { vm.contentType = "thread" }
            Button("كابشن") { vm.contentType = "caption" }
            Button("لينكدإن") { vm.contentType = "linkedin" }
            Button("إعلان") { vm.contentType = "ad" }
        } label: { controlPill(icon: "doc.text", title: contentLabel) }
    }

    private var dialectMenu: some View {
        Menu {
            Button("خليجية") { vm.dialect = "gulf" }
            Button("فصحى") { vm.dialect = "msa" }
            Button("مصرية") { vm.dialect = "egyptian" }
            Button("شامية") { vm.dialect = "levantine" }
        } label: { controlPill(icon: "quote.bubble", title: dialectLabel) }
    }

    private func controlPill(icon: String, title: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .foregroundStyle(accent)
            Text(title)
            Spacer(minLength: 2)
            Image(systemName: "chevron.down")
                .font(.system(size: 9, weight: .bold))
        }
        .font(.system(size: 13, weight: .bold))
        .foregroundStyle(ink)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(mist.opacity(0.55), in: RoundedRectangle(cornerRadius: 15))
    }

    private var contentLabel: String {
        ["tweets":"تغريدة","thread":"ثريد","caption":"كابشن","linkedin":"لينكدإن","ad":"إعلان"][vm.contentType] ?? "تغريدة"
    }

    private var dialectLabel: String {
        ["gulf":"خليجية","msa":"فصحى","egyptian":"مصرية","levantine":"شامية"][vm.dialect] ?? "خليجية"
    }

    private func publish(to target: String) {
        let encoded = vm.result.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let primary: String
        let fallback: String
        switch target {
        case "whatsapp":
            primary = "whatsapp://send?text=\(encoded)"
            fallback = "https://wa.me/?text=\(encoded)"
        case "telegram":
            primary = "tg://msg?text=\(encoded)"
            fallback = "https://t.me/share/url?url=&text=\(encoded)"
        default:
            primary = "twitter://post?message=\(encoded)"
            fallback = "https://twitter.com/intent/tweet?text=\(encoded)"
        }
        guard let url = URL(string: primary) else { showShare = true; return }
        UIApplication.shared.open(url, options: [:]) { opened in
            if !opened, let fallbackURL = URL(string: fallback) {
                UIApplication.shared.open(fallbackURL)
            }
        }
    }
}

private struct Entrance: ViewModifier {
    let active: Bool
    let delay: Double
    let y: CGFloat

    func body(content: Content) -> some View {
        content
            .opacity(active ? 1 : 0)
            .offset(y: active ? 0 : y)
            .scaleEffect(active ? 1 : 0.97)
            .blur(radius: active ? 0 : 7)
            .animation(.spring(response: 0.68, dampingFraction: 0.82).delay(delay), value: active)
    }
}

private struct BubblePulse: ViewModifier {
    let delay: Double
    @State private var up = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(up ? 1.35 : 0.68)
            .opacity(up ? 1 : 0.38)
            .offset(y: up ? -2 : 2)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(delay)) {
                    up = true
                }
            }
    }
}

private struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.86 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.75), value: configuration.isPressed)
    }
}
