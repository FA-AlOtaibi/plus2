import SwiftUI

struct ContentView: View {
    @StateObject private var vm = StudioViewModel()
    @State private var showSettings = false
    @State private var showHistory = false
    @State private var showShare = false
    @State private var showPublishMenu = false
    @FocusState private var focused: Bool

    private let paper = Color(red: 0.965, green: 0.958, blue: 0.935)
    private let ink = Color(red: 0.075, green: 0.075, blue: 0.07)
    private let accent = Color(red: 0.91, green: 0.36, blue: 0.23)
    private let moss = Color(red: 0.17, green: 0.29, blue: 0.22)

    var body: some View {
        NavigationStack {
            ZStack {
                paper.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 0) {
                        header
                        intro
                        studioCard
                        if !vm.result.isEmpty || !vm.error.isEmpty { resultCard.padding(.top, 14) }
                        Spacer(minLength: 40)
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
            .confirmationDialog("وين تبي تنشر؟", isPresented: $showPublishMenu, titleVisibility: .visible) {
                Button("X") { publish(to: "x") }
                Button("واتساب") { publish(to: "whatsapp") }
                Button("تيليجرام") { publish(to: "telegram") }
                Button("مشاركة عبر iOS") { showShare = true }
                Button("إلغاء", role: .cancel) {}
            }
        }
        .tint(accent)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Button { showHistory = true } label: { iconButton("clock.arrow.circlepath") }
            Button { showSettings = true } label: { iconButton("slider.horizontal.3") }
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                Text("سرد").font(.system(size: 25, weight: .black, design: .rounded))
                Text("فكرتك، بصوت أفضل").font(.caption).foregroundStyle(.secondary)
            }
            ZStack {
                RoundedRectangle(cornerRadius: 13).fill(ink)
                Text("س").font(.title2.black()).foregroundStyle(paper)
            }.frame(width: 46, height: 46)
        }
        .foregroundStyle(ink)
        .padding(.vertical, 8)
    }

    private func iconButton(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 16, weight: .semibold))
            .frame(width: 40, height: 40)
            .background(Color.white.opacity(0.75), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.06)))
    }

    private var intro: some View {
        VStack(alignment: .trailing, spacing: 8) {
            Text("لا نكرر فكرتك. نبني عليها.")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .trailing)
            Text("اكتبها مثل ما هي في بالك؛ سرد يستنبط الزاوية والفائدة والإيقاع، ثم يعطيك نصاً تقدر تعدله أو تنشره إذا رغبت.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 16)
    }

    private var studioCard: some View {
        VStack(spacing: 16) {
            VStack(alignment: .trailing, spacing: 8) {
                HStack {
                    Text("اكتب الفكرة").font(.headline)
                    Spacer()
                    Text("01").font(.caption2.bold()).foregroundStyle(accent)
                }
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.78))
                    TextEditor(text: $vm.topic)
                        .focused($focused)
                        .scrollContentBackground(.hidden)
                        .font(.system(size: 21, weight: .medium))
                        .lineSpacing(5)
                        .padding(14)
                        .frame(minHeight: 170)
                    if vm.topic.isEmpty {
                        Text("مثال: تطبيق يأخذ فكرتي الخام ويحوّلها إلى نص جميل له معنى وشخصية…")
                            .foregroundStyle(.tertiary)
                            .padding(20)
                            .allowsHitTesting(false)
                    }
                }
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.black.opacity(0.07)))
            }

            controls

            Button {
                focused = false
                Task { await vm.generate() }
            } label: {
                HStack(spacing: 10) {
                    if vm.isLoading { ProgressView().tint(.white) }
                    Image(systemName: "sparkles")
                    Text(vm.isLoading ? "جالس أصيغها…" : "اسردها")
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .background(vm.topic.trimmingCharacters(in: .whitespacesAndNewlines).count < 3 ? Color.gray : ink, in: RoundedRectangle(cornerRadius: 15))
            .disabled(vm.topic.trimmingCharacters(in: .whitespacesAndNewlines).count < 3 || vm.isLoading)
        }
        .padding(16)
        .background(Color.white.opacity(0.48), in: RoundedRectangle(cornerRadius: 26))
        .overlay(RoundedRectangle(cornerRadius: 26).stroke(Color.black.opacity(0.055)))
    }

    private var controls: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                menuChip(title: contentLabel, icon: "doc.text", menu: {
                    Button("تغريدة") { vm.contentType = "tweets" }
                    Button("ثريد") { vm.contentType = "thread" }
                    Button("كابشن") { vm.contentType = "caption" }
                    Button("لينكدإن") { vm.contentType = "linkedin" }
                    Button("إعلان") { vm.contentType = "ad" }
                })
                menuChip(title: dialectLabel, icon: "quote.bubble", menu: {
                    Button("خليجية") { vm.dialect = "gulf" }
                    Button("فصحى") { vm.dialect = "msa" }
                    Button("مصرية") { vm.dialect = "egyptian" }
                    Button("شامية") { vm.dialect = "levantine" }
                })
                menuChip(title: toneLabel, icon: "waveform", menu: {
                    Button("ودودة") { vm.tone = "friendly" }
                    Button("رسمية") { vm.tone = "formal" }
                    Button("جريئة") { vm.tone = "bold" }
                    Button("فكاهية") { vm.tone = "funny" }
                    Button("ملهمة") { vm.tone = "inspiring" }
                })
            }
        }
    }

    private func menuChip(title: String, icon: String, @ViewBuilder menu: () -> some View) -> some View {
        Menu(content: menu) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.caption)
                Text(title).font(.caption.bold()).lineLimit(1)
                Image(systemName: "chevron.down").font(.system(size: 9, weight: .bold))
            }
            .foregroundStyle(ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background(Color.white.opacity(0.82), in: Capsule())
            .overlay(Capsule().stroke(Color.black.opacity(0.06)))
        }
        .frame(maxWidth: .infinity)
    }

    private var resultCard: some View {
        VStack(alignment: .trailing, spacing: 14) {
            HStack {
                Text("النص").font(.headline)
                Text("02").font(.caption2.bold()).foregroundStyle(accent)
                Spacer()
                if !vm.result.isEmpty {
                    Text(vm.provider).font(.caption2).foregroundStyle(.secondary)
                }
            }

            if !vm.error.isEmpty {
                Text(vm.error).foregroundStyle(.red).frame(maxWidth: .infinity, alignment: .trailing)
            }

            if !vm.result.isEmpty {
                TextEditor(text: $vm.result)
                    .scrollContentBackground(.hidden)
                    .font(.system(size: 19, weight: .regular))
                    .lineSpacing(7)
                    .frame(minHeight: 260)
                    .padding(12)
                    .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 18))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.black.opacity(0.06)))

                HStack(spacing: 10) {
                    Button { UIPasteboard.general.string = vm.result } label: {
                        Label("نسخ", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(ActionPillStyle(background: Color.white, foreground: ink))

                    Button { Task { await vm.regenerate() } } label: {
                        Label("صياغة ثانية", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .buttonStyle(ActionPillStyle(background: Color.white, foreground: ink))

                    Button { showPublishMenu = true } label: {
                        Label("نشر", systemImage: "paperplane.fill")
                    }
                    .buttonStyle(ActionPillStyle(background: accent, foreground: .white))
                }
            }
        }
        .padding(16)
        .background(moss.opacity(0.07), in: RoundedRectangle(cornerRadius: 26))
        .overlay(RoundedRectangle(cornerRadius: 26).stroke(moss.opacity(0.12)))
    }

    private var contentLabel: String {
        ["tweets":"تغريدة","thread":"ثريد","caption":"كابشن","linkedin":"لينكدإن","ad":"إعلان"][vm.contentType] ?? "تغريدة"
    }
    private var dialectLabel: String {
        ["gulf":"خليجية","msa":"فصحى","egyptian":"مصرية","levantine":"شامية"][vm.dialect] ?? "خليجية"
    }
    private var toneLabel: String {
        ["friendly":"ودودة","formal":"رسمية","bold":"جريئة","funny":"فكاهية","inspiring":"ملهمة"][vm.tone] ?? "ودودة"
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
            if !opened, let fallbackURL = URL(string: fallback) { UIApplication.shared.open(fallbackURL) }
        }
    }
}

private struct ActionPillStyle: ButtonStyle {
    let background: Color
    let foreground: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.bold())
            .foregroundStyle(foreground)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(background.opacity(configuration.isPressed ? 0.7 : 1), in: Capsule())
            .overlay(Capsule().stroke(Color.black.opacity(background == Color.white ? 0.06 : 0)))
    }
}
