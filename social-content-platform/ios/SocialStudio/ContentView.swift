import SwiftUI

struct ContentView: View {
    @StateObject private var vm = StudioViewModel()
    @State private var showSettings = false
    @State private var showHistory = false
    @State private var showShare = false
    @State private var publishTarget = "x"

    private let cream = Color(red: 0.953, green: 0.941, blue: 0.906)
    private let ink = Color(red: 0.09, green: 0.09, blue: 0.075)
    private let green = Color(red: 0.153, green: 0.365, blue: 0.29)

    var body: some View {
        NavigationStack {
            ZStack {
                cream.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .trailing, spacing: 22) {
                        header
                        hero
                        options
                        composer
                        output
                    }.padding(18)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showSettings) { SettingsView(vm: vm) }
            .sheet(isPresented: $showHistory) { HistoryView(vm: vm) }
            .sheet(isPresented: $showShare) { ShareSheet(items: [vm.result]) }
        }
    }

    private var header: some View {
        HStack {
            Button { showSettings = true } label: { Image(systemName: "slider.horizontal.3").frame(width: 42, height: 42).background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 12)) }
            Button { showHistory = true } label: { Image(systemName: "clock.arrow.circlepath").frame(width: 42, height: 42).background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 12)) }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) { Text("سرد").font(.title2.bold()); Text("استوديو المحتوى العربي").font(.caption).foregroundStyle(.secondary) }
            Text("س").font(.title2.bold()).foregroundStyle(.white).frame(width: 44, height: 44).background(ink, in: RoundedRectangle(cornerRadius: 12))
        }.foregroundStyle(ink)
    }

    private var hero: some View {
        VStack(alignment: .trailing, spacing: 10) {
            Text("محتوى عربي لا يبدو آلياً").font(.caption.bold()).foregroundStyle(green)
            Text("حوّل الفكرة إلى منشور\nيستحق النشر.").font(.system(size: 37, weight: .bold, design: .rounded)).frame(maxWidth: .infinity, alignment: .trailing)
            Text("اكتب الفكرة، اختر المنصة، وسنفتح لك شاشة النشر مباشرة بعد تجهيز النص.").font(.subheadline).foregroundStyle(.secondary).lineSpacing(5)
        }
    }

    private var options: some View {
        VStack(spacing: 14) {
            Picker("النوع", selection: $vm.contentType) { Text("تغريدات").tag("tweets"); Text("ثريد").tag("thread"); Text("كابشن").tag("caption"); Text("لينكدإن").tag("linkedin"); Text("إعلان").tag("ad") }.pickerStyle(.segmented)
            HStack {
                Picker("النبرة", selection: $vm.tone) { Text("ودودة").tag("friendly"); Text("رسمية").tag("formal"); Text("جريئة").tag("bold"); Text("فكاهية").tag("funny"); Text("ملهمة").tag("inspiring") }.pickerStyle(.menu)
                Spacer()
                Picker("اللهجة", selection: $vm.dialect) { Text("خليجية").tag("gulf"); Text("فصحى").tag("msa"); Text("مصرية").tag("egyptian"); Text("شامية").tag("levantine") }.pickerStyle(.menu)
            }.padding(.horizontal, 4)
            Divider()
            HStack {
                Text("النشر إلى").font(.caption.bold()).foregroundStyle(.secondary)
                Spacer()
                Picker("المنصة", selection: $publishTarget) {
                    Text("X").tag("x")
                    Text("واتساب").tag("whatsapp")
                    Text("تيليجرام").tag("telegram")
                    Text("أخرى").tag("share")
                }.pickerStyle(.menu)
            }
        }.padding(16).background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 18))
    }

    private var composer: some View {
        VStack(alignment: .trailing, spacing: 12) {
            HStack { Text("01").font(.caption2.bold()).foregroundStyle(green); Text("الفكرة").font(.subheadline.bold()); Spacer() }
            TextEditor(text: $vm.topic).scrollContentBackground(.hidden).frame(minHeight: 155).font(.title3).overlay(alignment: .topTrailing) { if vm.topic.isEmpty { Text("اكتب موضوع المنشور أو الكلمات المفتاحية هنا…").foregroundStyle(.tertiary).padding(.top, 8).allowsHitTesting(false) } }
            Divider()
            Button {
                Task {
                    await vm.generate()
                    if vm.error.isEmpty && !vm.result.isEmpty { openPublishTarget(vm.result) }
                }
            } label: {
                HStack { if vm.isLoading { ProgressView().tint(.white) }; Text(vm.isLoading ? "جاري الصياغة…" : "ولّد وانشر").fontWeight(.bold) }.frame(maxWidth: .infinity).padding(.vertical, 14)
            }.buttonStyle(.plain).foregroundStyle(.white).background(green, in: RoundedRectangle(cornerRadius: 13)).disabled(vm.topic.trimmingCharacters(in: .whitespacesAndNewlines).count < 3 || vm.isLoading).opacity(vm.topic.trimmingCharacters(in: .whitespacesAndNewlines).count < 3 ? 0.45 : 1)
        }.padding(18).background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 18))
    }

    @ViewBuilder private var output: some View {
        VStack(alignment: .trailing, spacing: 14) {
            HStack { Text("02").font(.caption2.bold()).foregroundStyle(green); Text("معاينة المنشور").font(.subheadline.bold()); Spacer(); if !vm.result.isEmpty { Button { openPublishTarget(vm.result) } label: { Label("فتح المنصة", systemImage: "paperplane.fill") }.font(.caption.bold()).foregroundStyle(.white).padding(.horizontal, 12).padding(.vertical, 8).background(green, in: Capsule()) } }
            if !vm.error.isEmpty { Text(vm.error).foregroundStyle(.red).frame(maxWidth: .infinity, alignment: .trailing) }
            if vm.result.isEmpty && vm.error.isEmpty && !vm.isLoading { VStack(spacing: 8) { Image(systemName: "sparkles").font(.largeTitle).foregroundStyle(green); Text("اكتب فكرتك واختر المنصة").font(.headline); Text("بعد التوليد سنفتح منصة النشر المحددة تلقائياً.").font(.caption).foregroundStyle(.secondary) }.frame(maxWidth: .infinity).padding(.vertical, 36) }
            if !vm.result.isEmpty { Text(vm.result).font(.body).lineSpacing(8).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .trailing); Divider(); Button { openPublishTarget(vm.result) } label: { Label("افتح منصة النشر المحددة", systemImage: "paperplane.fill").fontWeight(.bold).frame(maxWidth: .infinity).padding(.vertical, 13) }.buttonStyle(.plain).foregroundStyle(.white).background(green, in: RoundedRectangle(cornerRadius: 13)); Text("المحرّك: \(vm.provider)").font(.caption2).foregroundStyle(.secondary) }
        }.padding(18).background(Color(red:0.975,green:0.961,blue:0.925), in: RoundedRectangle(cornerRadius: 18))
    }

    private func openPublishTarget(_ text: String) {
        let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if publishTarget == "share" { showShare = true; return }

        let primary: String
        let fallback: String
        switch publishTarget {
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

        guard let primaryURL = URL(string: primary) else { showShare = true; return }
        UIApplication.shared.open(primaryURL, options: [:]) { opened in
            if !opened, let fallbackURL = URL(string: fallback) {
                UIApplication.shared.open(fallbackURL)
            }
        }
    }
}
