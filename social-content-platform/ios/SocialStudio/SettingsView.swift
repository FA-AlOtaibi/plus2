import SwiftUI

struct SettingsView: View {
    @ObservedObject var vm: StudioViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("صوت العلامة") {
                    TextEditor(text: $vm.brand).frame(minHeight: 120)
                }

                Section("الذكاء الاصطناعي المباشر") {
                    SecureField("HF Token", text: $vm.hfToken)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Text("إذا أضفته هنا يستخدم التطبيق Qwen من Hugging Face مباشرة، بدون المحرك الاحتياطي.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("الخادم") {
                    TextField("https://your-project.vercel.app", text: $vm.serverURL)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                    Text("اتركه فارغاً لاستخدام خادم الإنتاج المدمج.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button("حفظ") {
                        vm.saveSettings()
                        dismiss()
                    }
                }
            }
            .navigationTitle("الإعدادات")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
