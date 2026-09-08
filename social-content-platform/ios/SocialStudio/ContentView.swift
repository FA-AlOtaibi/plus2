import SwiftUI

struct ContentView: View {
    @StateObject private var vm = StudioViewModel()
    @State private var showSettings = false
    @State private var showHistory = false
    @State private var showShare = false
    @State private var showPublishMenu = false
    @State private var introVisible = true
    @State private var introPulse = false
    @State private var stage = 0
    @FocusState private var focused: Bool

    private let bg = Color(red: 0.965, green: 0.955, blue: 0.925)
    private let ink = Color(red: 0.055, green: 0.055, blue: 0.05)
    private let accent = Color(red: 0.92, green: 0.29, blue: 0.16)

    var body: some View {
        NavigationStack {
            ZStack {
                bg.ignoresSafeArea()

                Circle()
                    .fill(accent.opacity(0.09))
                    .frame(width: 300, height: 300)
                    .blur(radius: 24)
                    .offset(x: introPulse ? 145 : 105, y: introPulse ? -260 : -215)
                    .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: introPulse)

                Circle()
                    .fill(Color.black.opacity(0.04))
                    .frame(width: 240, height: 240)
                    .blur(radius: 20)
                    .offset(x: introPulse ? -130 : -90, y: introPulse ? 350 : 305)
                    .animation(.easeInOut(duration: 4.8).repeatForever(autoreverses: true), value: introPulse)

                ScrollView {
                    VStack(spacing: 22) {
                        reveal(topBar, at: 1, y: -24, scale: 0.96)
                        reveal(masthead, at: 2, y: 28, scale: 0.95)
                        reveal(editor, at: 3, y: 42, scale: 0.94)

                        if vm.isLoading {
                            thinkingCard
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.88).combined(with: .opacity).combined(with: .move(edge: .bottom)),
                                    removal: .opacity.combined(with: .scale(scale: 0.96))
                                ))
                        }

                        if !vm.result.isEmpty || !vm.error.isEmpty {
                            draft
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.94)),
                                    removal: .opacity
                                ))
                        }
                        Spacer(minLength: 60)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                }
                .scrollDismissesKeyboard(.interactively)

                if introVisible {
                    launchOverlay
                        .transition(.opacity)
                        .zIndex(20)
                }
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
        .task { await runLaunchSequence() }
    }

    private var launchOverlay: some View {
        ZStack {
            Color(red: 0.965, green: 0.955, blue: 0.925).ignoresSafeArea()

            VStack(spacing: 22) {
                ZStack {
                    Circle()
                        .fill(accent.opacity(0.12))
                        .frame(width: 128, height: 128)
                        .scaleEffect(introPulse ? 1.12 : 0.90)
                    Circle()
                        .fill(accent.opacity(0.16))
                        .frame(width: 88, height: 88)
                        .scaleEffect(introPulse ? 0.94 : 1.06)
                    Text("س")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundStyle(accent)
                }

                VStack(spacing: 7) {
                    Text("سرد")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                    Text("نحوّل الفكرة الخام إلى نص له صوت")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 7) {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(i == (stage % 3) ? accent : Color.black.opacity(0.14))
                            .frame(width: 8, height: 8)
                            .scaleEffect(i == (stage % 3) ? 1.35 : 0.85)
                            .animation(.spring(response: 0.4, dampingFraction: 0.68), value: stage)
                    }
                }
                .padding(.top, 6)
            }
            .scaleEffect(introPulse ? 1.0 : 0.92)
            .opacity(introPulse ? 1 : 0.72)
        }
    }

    private func reveal<V: View>(_ view: V, at target: Int, y: CGFloat, scale: CGFloat) -> some View {
        view
            .opacity(stage >= target ? 1 : 0)
            .offset(y: stage >= target ? 0 : y)
            .scaleEffect(stage >= target ? 1 : scale)
            .blur(radius: stage >= target ? 0 : 8)
            .animation(.spring(response: 0.62, dampingFraction: 0.78), value: stage)
    }

    private func runLaunchSequence() async {
        introPulse = true
        try? await Task.sleep(nanoseconds: 550_000_000)
        await MainActor.run { withAnimation(.easeOut(duration: 0.35)) { stage = 1 } }
        try? await Task.sleep(nanoseconds: 220_000_000)
        await MainActor.run { withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) { stage = 2 } }
        try? await Task.sleep(nanoseconds: 220_000_000)
        await MainActor.run { withAnimation(.spring(response: 0.58, dampingFraction: 0.78)) { stage = 3 } }
        try? await Task.sleep(nanoseconds: 380_000_000)
        await MainActor.run { withAnimation(.easeInOut(duration: 0.45)) { introVisible = false } }
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 1) {
                Text("سرد")
                    .font(.system(size: 29, weight: .black, design: .rounded))
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
            .frame(width: 44, height: 44)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
    }

    private var masthead: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 8) {
                Capsule().fill(accent).frame(width: 48, height: 5)
                Capsule().fill(ink.opacity(0.12)).frame(height: 5)
            }
            Text("ارمِ الفكرة.\nخلّنا نبني النص.")
                .font(.system(size: 41, weight: .black, design: .rounded))
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("اكتبها مثل ما هي في بالك. نلتقط العرض، الفائدة، الزاوية، ونبني منها صياغة ما تشبه اللي قبلها.")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)
                .lineSpacing(5)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var editor: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("الفكرة الخام")
                        .font(.system(size: 16, weight: .bold))
                    Text("ما تحتاج ترتبها")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(accent)
                    .frame(width: 38, height: 38)
                    .background(accent.opacity(0.09), in: Circle())
            }

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(0.88))
                    .shadow(color: .black.opacity(0.05), radius: 16, y: 7)

                TextEditor(text: $vm.topic)
                    .focused($focused)
                    .scrollContentBackground(.hidden)
                    .font(.system(size: 22, weight: .medium))
                    .lineSpacing(7)
                    .padding(16)
                    .frame(minHeight: 225)

                if vm.topic.isEmpty {
                    Text("مثال: عسل سدر بـ150 ريال، العلبة كيلو، هدية للوالد أو للصباح، والتوصيل اليوم مجاني لكل المدن…")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(.secondary.opacity(0.72))
                        .padding(21)
                        .allowsHitTesting(false)
                }
            }

            HStack(spacing: 8) {
                formatMenu
                dialectMenu
                toneMenu
            }

            Button {
                focused = false
                withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) { }
                Task { await vm.generate() }
            } label: {
                HStack(spacing: 10) {
                    if vm.isLoading { ProgressView().tint(.white) }
                    Text(vm.isLoading ? "نبني زاوية جديدة…" : "ابنِ النص")
                        .font(.system(size: 17, weight: .bold))
                    Image(systemName: "arrow.left")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
            }
            .buttonStyle(PressableButtonStyle())
            .foregroundStyle(.white)
            .background(canGenerate ? ink : Color.gray.opacity(0.65), in: RoundedRectangle(cornerRadius: 18))
            .disabled(!canGenerate || vm.isLoading)
        }
        .padding(17)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30))
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.white.opacity(0.55), lineWidth: 1))
    }

    private var thinkingCard: some View {
        HStack(spacing: 13) {
            HStack(spacing: 5) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(accent)
                        .frame(width: 7, height: 7)
                        .modifier(BubblePulse(delay: Double(index) * 0.16))
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("سرد يفكر")
                    .font(.system(size: 15, weight: .bold))
                Text("نبحث عن زاوية مختلفة عن الصياغات السابقة")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "wand.and.stars")
                .foregroundStyle(accent)
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(accent.opacity(0.15), lineWidth: 1))
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
        .padding(.vertical, 11)
        .background(Color.white.opacity(0.82), in: Capsule())
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }

    private var draft: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("المسودة")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                    if !vm.provider.isEmpty {
                        Text(vm.provider.uppercased())
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .tracking(1.2)
                            .foregroundStyle(.white.opacity(0.45))
                    }
                }
                Spacer()
                Image(systemName: "quote.opening")
                    .font(.system(size: 29, weight: .bold))
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
                    .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 20))

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
        .background(ink, in: RoundedRectangle(cornerRadius: 30))
        .shadow(color: .black.opacity(0.12), radius: 18, y: 10)
    }

    private func actionButton(_ title: String, icon: String, filled: Bool, action: @escaping () -> Void) -> some View {
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
        .foregroundStyle(.white)
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

private struct BubblePulse: ViewModifier {
    let delay: Double
    @State private var up = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(up ? 1.35 : 0.65)
            .opacity(up ? 1 : 0.45)
            .offset(y: up ? -3 : 3)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true).delay(delay)) {
                    up = true
                }
            }
    }
}

private struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.965 : 1)
            .opacity(configuration.isPressed ? 0.86 : 1)
            .animation(.spring(response: 0.24, dampingFraction: 0.72), value: configuration.isPressed)
    }
}
