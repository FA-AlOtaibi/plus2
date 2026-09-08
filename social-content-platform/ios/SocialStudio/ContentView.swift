import SwiftUI

struct ContentView: View {
    @StateObject private var vm = StudioViewModel()
    @State private var showSettings = false
    @State private var showHistory = false
    @State private var showShare = false
    @State private var showPublishMenu = false
    @FocusState private var focused: Bool

    private let bg = Color(red: 0.965, green: 0.955, blue: 0.925)
    private let ink = Color(red: 0.055, green: 0.055, blue: 0.05)
    private let accent = Color(red: 0.92, green: 0.29, blue: 0.16)

    var body: some View {
        NavigationStack {
            ZStack {
                bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 22) {
                        topBar
                        masthead
                        editor
                        if !vm.result.isEmpty || !vm.error.isEmpty { draft }
                        Spacer(minLength: 48)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
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
            .background(Color.white.opacity(0.64))
            .clipShape(RoundedRectangle(cornerRadius: 11))
    }

    private var masthead: some View {
        VStack(alignment: .leading, spacing: 12) {
            Rectangle().fill(ink).frame(height: 4)
            Text("ارمِ الفكرة.\nخلّنا نبني النص.")
                .font(.system(size: 41, weight: .black, design: .rounded))
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("ما نعيد كلامك بصياغة أفخم. نلتقط العرض، الفائدة، الزاوية، ونبني منها منشوراً له بداية ونهاية.")
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
                Color.white.opacity(0.78)
                TextEditor(text: $vm.topic)
                    .focused($focused)
                    .scrollContentBackground(.hidden)
                    .font(.system(size: 22, weight: .medium))
                    .lineSpacing(7)
                    .padding(16)
                    .frame(minHeight: 220)
                if vm.topic.isEmpty {
                    Text("مثال: عسل سدر بـ150 ريال، العلبة كيلو، هدية للوالد أو للصباح، والتوصيل اليوم مجاني لكل المدن…")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(.secondary.opacity(0.72))
                        .padding(20)
                        .allowsHitTesting(false)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))

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
                    if vm.isLoading { ProgressView().tint(.white) }
                    Text(vm.isLoading ? "نبني النص…" : "ابنِ النص")
                        .font(.system(size: 17, weight: .bold))
                    Image(systemName: "arrow.left")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .background(canGenerate ? ink : Color.gray.opacity(0.65), in: RoundedRectangle(cornerRadius: 16))
            .padding(.top, 12)
            .disabled(!canGenerate || vm.isLoading)
        }
        .padding(16)
        .background(Color.white.opacity(0.30), in: RoundedRectangle(cornerRadius: 28))
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
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.72), in: Capsule())
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
        .buttonStyle(.plain)
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
