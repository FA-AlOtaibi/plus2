import SwiftUI

struct SettingsView: View {
    @ObservedObject var vm: StudioViewModel
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            Form {
                Section("صوت العلامة") { TextEditor(text:$vm.brand).frame(minHeight:120) }
                Section("الخادم") {
                    TextField("https://your-project.vercel.app",text:$vm.serverURL).textInputAutocapitalization(.never).keyboardType(.URL)
                    Text("اتركه فارغاً لاستخدام خادم الإنتاج المدمج.").font(.caption).foregroundStyle(.secondary)
                }
                Section { Button("حفظ") { vm.saveServerURL(); dismiss() } }
            }
            .navigationTitle("الإعدادات")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
