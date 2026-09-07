import Foundation

struct HistoryItem: Identifiable, Codable { let id:UUID; let createdAt:Date; let topic:String; let text:String; let type:String }

@MainActor
final class StudioViewModel: ObservableObject {
    @Published var topic=""; @Published var brand=""; @Published var contentType="tweets"; @Published var dialect="gulf"; @Published var tone="friendly"; @Published var result=""; @Published var provider=""; @Published var error=""; @Published var isLoading=false; @Published var history:[HistoryItem]=[]; @Published var serverURL=UserDefaults.standard.string(forKey:"serverURL") ?? ""
    init(){ loadHistory() }
    func generate() async {
        guard topic.trimmingCharacters(in:.whitespacesAndNewlines).count >= 3 else { return }
        isLoading=true; error=""; result=""
        do { let r = try await APIClient.shared.generate(.init(topic:topic,brand:brand,contentType:contentType,dialect:dialect,tone:tone), customBaseURL:serverURL); result=r.text ?? ""; provider=r.provider ?? "AI"; history.insert(.init(id:UUID(),createdAt:Date(),topic:topic,text:result,type:contentType),at:0); if history.count > 30 { history.removeLast(history.count-30) }; saveHistory() } catch { self.error=error.localizedDescription }
        isLoading=false
    }
    func saveServerURL(){ UserDefaults.standard.set(serverURL,forKey:"serverURL") }
    func clearHistory(){ history=[]; saveHistory() }
    private func saveHistory(){ if let d=try? JSONEncoder().encode(history){ UserDefaults.standard.set(d,forKey:"history") } }
    private func loadHistory(){ if let d=UserDefaults.standard.data(forKey:"history"), let h=try? JSONDecoder().decode([HistoryItem].self,from:d){ history=h } }
}
