import SwiftUI

struct HistoryView: View {
    @ObservedObject var vm: StudioViewModel
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List {
                ForEach(vm.history) { item in
                    Button {
                        vm.result=item.text; vm.topic=item.topic; dismiss()
                    } label: {
                        VStack(alignment:.trailing,spacing:6) {
                            Text(item.topic).font(.headline).lineLimit(1).frame(maxWidth:.infinity,alignment:.trailing)
                            Text(item.text).font(.caption).foregroundStyle(.secondary).lineLimit(2).frame(maxWidth:.infinity,alignment:.trailing)
                            Text(item.createdAt,style:.relative).font(.caption2).foregroundStyle(.tertiary)
                        }
                    }.buttonStyle(.plain)
                }
            }
            .overlay { if vm.history.isEmpty { ContentUnavailableView("لا يوجد سجل بعد",systemImage:"clock") } }
            .navigationTitle("السجل")
            .toolbar { ToolbarItem(placement:.topBarLeading) { Button("مسح") { vm.clearHistory() }.disabled(vm.history.isEmpty) } }
        }
    }
}
