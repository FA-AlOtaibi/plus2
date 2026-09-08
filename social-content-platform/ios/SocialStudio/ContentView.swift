import SwiftUI

struct ContentView: View {
    @StateObject private var vm = StudioViewModel()
    @State private var showSettings = false
    @State private var showHistory = false
    @State private var showShare = false
    @State private var showPublishMenu = false

    @State private var showTop = false
    @State private var showMasthead = false
    @State private var showEditor = false
    @State private var bubbleFloat = false
    @State private var thinkingIndex = 0

    @FocusState private var focused: Bool

    private let bg = Color(red: 0.965, green: 0.955, blue: 0.925)
    private let ink = Color(red: 0.055, green: 0.055, blue: 0.05)
    private let accent = Color(red: 0.92, green: 0.29, blue: 0.16)

    var body: some View {
        NavigationStack {
            ZStack {
                bg.ignoresSafeArea()
                ambientBubbles

                ScrollView {
                    VStack(spacing: 22) {
                        topBar
                            .entrance(showTop, y: -16, scale: 0.96)

                        masthead
                            .entrance(showMasthead, y: 22, scale: 0.985)

                        editor
                            .entrance(showEditor, y: 30, scale: 0.97)

                        if vm.isLoading {
                            thinkingBubble
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.92, anchor: .top).combined(with: .opacity).combined(with: .move(edge: .top)),
                                    removal: .scale(scale: 0.97).combined(with: .opacity)
                                ))
                        }

                        if !vm.result.isEmpty || !vm.error.isEmpty {
                            draft
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.94, anchor: .top).combined(with: .opacity).combined(with: .move(edge: .top)),
                                    removal: .opacity
                                ))
                        }

                        Spacer(minLength: 48)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                    .animation(.spring(response: 0.58, dampingFraction: 0.84), value: vm.isLoading)
                    .animation(.spring(response: 0.62, dampingFraction: 0.82), value: vm.result)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showSettings) { SettingsView(vm: vm) }
            .sheet(isPresented: $showHistory) { HistoryView(vm: vm) }
            .sheet(isPresented: $showShare) { ShareSheet(items: [vm.result]) }
            .confirmationDialog("اختر مكان النشر", isPresented: $showPublishMenu, titleVisibility: .visible) {
                Button("X") { publish(to: "x") }
                Button("واتساب") { publish(to: "whatsapp") }
                Button("تيليجرام") { publish(to: "telegram") }
                Button("مشاركة عبر iOS") { showShare = true }
                Button("إلغاء", role: .cancel) {}
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .tint(accent)
        .onAppear { runEntranceSequence() }
        .task(id: vm.isLoading) {
            guard vm.isLoading else { return }
            thinkingIndex = 0
            while vm.isLoading {
                try? await Task.sleep(nanoseconds: 1_050_000_000)
                if vm.isLoading {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        thinkingIndex = (thinkingIndex + 1) % thinkingMessages.count
                    }
                }
            }
        }
    }

    private var ambientBubbles: some View {
        GeometryReader { proxy in
            ZStack {
                Circle()
                    .fill(accent.opacity(0.055))
                    .frame(width: 190, height: 190)
                    .blur(radius: 2)
                    .offset(x: bubbleFloat ? -55 : -82, y: bubbleFloat ? -250 : -215)

                Circle()
                    .fill(ink.opacity(0.035))
                    .frame(width: 260, height: 260)
                    .blur(radius: 3)
                    .offset(x: bubbleFloat ? proxy.size.width * 0.48 : proxy.size.width * 0.56,
                            y: bubbleFloat ? proxy.size.height * 0.34 : proxy.size.height * 0.29)

                Circle()
                    .fill(Color.white.opacity(0.40))
                    .frame(width: 115, height: 115)
                    .blur(radius: 1)
                    .offset(x: bubbleFloat ? -120 : -92, y: proxy.size.height * 0.58)
            }
            .animation(.easeInOut(duration: 5.5).repeatForever(autoreverses: true), value: bubbleFloat)
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }

    private func runEntranceSequence() {
        guard !showTop else { return }
        withAnimation(.spring(response: 0.52, dampingFraction: 0.78)) { showTop = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.11) {
            withAnimation(.spring(response: 0.58, dampingFraction: 0.80)) { showMasthead = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
            withAnimation(.spring(response: 0.64, dampingFraction: 0.82)) { showEditor = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
            bubbleFloat = true
        }
    }

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                Text("سرد")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                Text("SARD / EDITOR")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .tracking(1.8)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button { showHistory = true } label: { squareIcon("clock.arrow.circlepath") }
            Button { showSettings = true } label: { squareIcon("slider.horizontal.3") }
        }
    }

    private func squareIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(ink)
            .frame(width: 42, height: 42)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 11))
            .overlay(RoundedRectangle(cornerRadius: 11).stroke(Color.black.opacity(0.035)))
    }

    private var masthead: some View {
        VStack(alignment: .leading, spacing: 12) {
            Rectangle().fill(ink).frame(height: 4)
                .clipShape(Capsule())
            Text("ارمِ الفكرة.\nخلّنا نبني النص.")
                .font(.system(size: 41, weight: .black, design: .rounded))
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("ما نعيد كلامك بصياغة أفخم. نفهم المقصد، نلتقط الزاوية، ونبني لك نصاً جديداً من الصفر.")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)
                .lineSpacing(5)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var editor: some View {
        VStack(spacing: 0) {
            HStack {
                Text("المسودة الخام")
                    .font(.system(size: 13, weight: .bold))
                Spacer()
                Text("اكتبها بطريقتك")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 12)

            ZStack(alignment: .topLeading) {
                Color.white.opacity(0.80)
                TextEditor(text: $vm.topic)
                    .focused($focused)
                    .scrollContentBackground(.hidden)
                    .font(.system(size: 22, weight: .medium))
                    .lineSpacing(7)
                    .padding(16)
                    .frame(minHeight: 220)
                if vm.topic.isEmpty {
                    Text("مثال: عندي منتج جديد، سعره كذا، ميزته كذا، وأبي إعلان يخلي الناس تتحمس له بدون مبالغة…")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(.secondary.opacity(0.72))
                        .padding(20)
                        .allowsHitTesting(false)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.black.opacity(0.035)))
            .shadow(color: .black.opacity(0.025), radius: 18, y: 8)

            HStack(spacing: 8) {
                formatMenu
                dialectMenu
                toneMenu
            }
            .padding(.top, 12)

            Button {
                focused = false
                Task { await vm.generate() }
            } label: {
                HStack(spacing: 9) {
                    if vm.isLoading {
                        ProgressView().tint(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                    Text(vm.isLoading ? "نفكر في زاوية…" : "ابنِ النص")
                        .font(.system(size: 17, weight: .bold))
                        .contentTransition(.opacity)
                    Image(systemName: vm.isLoading ? "sparkles" : "arrow.left")
                        .symbolEffect(.pulse, options: .repeating, isActive: vm.isLoading)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .buttonStyle(PressScaleButtonStyle())
            .foregroundStyle(.white)
            .background(canGenerate ? ink : Color.gray.opacity(0.65), in: RoundedRectangle(cornerRadius: 16))
            .padding(.top, 12)
            .disabled(!canGenerate || vm.isLoading)
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28))
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.white.opacity(0.50)))
    }

    private var thinkingBubble: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.12))
                    .frame(width: 52, height: 52)
                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(accent)
                    .symbolEffect(.pulse, options: .repeating)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("سرد يفكر")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.secondary)

                Text(thinkingMessages[thinkingIndex])
                    .font(.system(size: 17, weight: .semibold))
                    .contentTransition(.opacity)
                    .id(thinkingIndex)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            Spacer()

            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(ink.opacity(0.65))
                        .frame(width: 6, height: 6)
                        .scaleEffect(thinkingIndex % 3 == i ? 1.45 : 0.75)
                        .opacity(thinkingIndex % 3 == i ? 1 : 0.35)
                        .animation(.easeInOut(duration: 0.35), value: thinkingIndex)
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.74), in: RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.black.opacity(0.04)))
        .shadow(color: .black.opacity(0.035), radius: 18, y: 10)
    }

    private let thinkingMessages = [
        "نستخرج أقوى زاوية من فكرتك…",
        "نبتعد عن الصياغات المتوقعة…",
        "نبني افتتاحية تشد بدون مبالغة…",
        "نراجع النبرة والإيقاع…",
        "نختار نسخة تستحق النشر…"
    ]

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
        } label: { pill(contentLabel) }
    }

    private var dialectMenu: some View {
        Menu {
            Button("خليجية") { vm.dialect = "gulf" }
            Button("فصحى") { vm.dialect = "msa" }
            Button("مصرية") { vm.dialect = "egyptian" }
            Button("شامية") { vm.dialect = "levantine" }
        } label: { pill(dialectLabel) }
    }

    private var toneMenu: some View {
        Menu {
            Button("ودودة") { vm.tone = "friendly" }
            Button("رسمية") { vm.tone = "formal" }
            Button("جريئة") { vm.tone = "bold" }
            Button("فكاهية") { vm.tone = "funny" }
            Button("ملهمة") { vm.tone = "inspiring" }
        } label: { pill(toneLabel) }
    }

    private func pill(_ title: String) -> some View {
        HStack(spacing: 5) {
            Text(title).lineLimit(1)
            Image(systemName: "chevron.down").font(.system(size: 9, weight: .bold))
        }
        .font(.caption.bold())
        .foregroundStyle(ink)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.76), in: Capsule())
        .overlay(Capsule().stroke(Color.black.opacity(0.035)))
    }

    private var draft: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("المسودة")
                        .font(.system(size: 27, weight: .black, design: .rounded))
                    if !vm.provider.isEmpty {
                        Text(vm.provider.uppercased())
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .tracking(1.2)
                            .foregroundStyle(.white.opacity(0.45))
                    }
                }
                Spacer()
                Image(systemName: "quote.opening")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(accent)
            }

            if !vm.error.isEmpty {
                Text(vm.error).foregroundStyle(.red)
            }

            if !vm.result.isEmpty {
                TextEditor(text: $vm.result)
                    .scrollContentBackground(.hidden)
                    .font(.system(size: 20, weight: .regular))
                    .lineSpacing(8)
                    .foregroundStyle(.white)
                    .frame(minHeight: 330)
                    .padding(14)
                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18))

                HStack(spacing: 8) {
                    actionButton("نسخ", icon: "doc.on.doc", filled: false) {
                        UIPasteboard.general.string = vm.result
                    }
                    actionButton("صياغة ثانية", icon: "arrow.triangle.2.circlepath", filled: false) {
                        Task { await vm.regenerate() }
                    }
                    actionButton("نشر", icon: "paperplane.fill", filled: true) {
                        showPublishMenu = true
                    }
                }
            }
        }
        .padding(18)
        .foregroundStyle(.white)
        .background(ink, in: RoundedRectangle(cornerRadius: 28))
        .shadow(color: .black.opacity(0.10), radius: 24, y: 14)
    }

    private func actionButton(_ title: String, icon: String, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                Text(title).lineLimit(1)
            }
            .font(.caption.bold())
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
        }
        .buttonStyle(PressScaleButtonStyle())
        .foregroundStyle(filled ? Color.white : Color.white.opacity(0.92))
        .background(filled ? accent : Color.white.opacity(0.10), in: Capsule())
    }

    private var contentLabel: String { ["tweets":"تغريدة","thread":"ثريد","caption":"كابشن","linkedin":"لينكدإن","ad":"إعلان"][vm.contentType] ?? "تغريدة" }
    private var dialectLabel: String { ["gulf":"خليجية","msa":"فصحى","egyptian":"مصرية","levantine":"شامية"][vm.dialect] ?? "خليجية" }
    private var toneLabel: String { ["friendly":"ودودة","formal":"رسمية","bold":"جريئة","funny":"فكاهية","inspiring":"ملهمة"][vm.tone] ?? "ودودة" }

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

private struct PressScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.965 : 1)
            .opacity(configuration.isPressed ? 0.90 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.78), value: configuration.isPressed)
    }
}

private extension View {
    func entrance(_ visible: Bool, y: CGFloat, scale: CGFloat) -> some View {
        self
            .opacity(visible ? 1 : 0)
            .blur(radius: visible ? 0 : 7)
            .scaleEffect(visible ? 1 : scale)
            .offset(y: visible ? 0 : y)
    }
}
