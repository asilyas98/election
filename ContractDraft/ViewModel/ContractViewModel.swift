import Foundation
import Combine

class ContractViewModel: ObservableObject {
    // Active type
    @Published var activeType: ContractTypeID = .loan
    @Published var activeTab: Int = 0  // 0=Details 1=Contract 2=Send 3=AI

    // Party info per type (keyed by type rawValue)
    @Published var party1: [String: Party] = [:]
    @Published var party2: [String: Party] = [:]

    // Per-type states
    @Published var loanState     = LoanState()
    @Published var leaseState    = LeaseState()
    @Published var serviceState  = ServiceState()
    @Published var ndaState      = NDAState()
    @Published var billState     = BillState()
    @Published var contractorState = ContractorState()

    // Contract IDs
    private var contractIds: [String: String] = [:]

    // AI Chat
    @Published var chatMessages: [ChatMessage] = []
    @Published var isSampling: Bool = false

    // Anthropic API key (user sets this)
    var anthropicAPIKey: String = ""  // Set via Settings or hard-code for testing

    init() {
        // Default parties
        let defaults: [ContractTypeID: (Party, Party)] = [
            .loan:       (Party(name: "Marcus Webb",        phone: "(313) 555-0191", email: "marcus@email.com"),
                          Party(name: "Jordan Ellis",        phone: "(313) 555-0274", email: "jellis@email.com")),
            .lease:      (Party(name: "Sandra Okafor",      phone: "(313) 555-0188", email: "sandra@realty.com"),
                          Party(name: "Daniel Kim",          phone: "(313) 555-0355", email: "dkim@email.com")),
            .service:    (Party(name: "Apex Corp LLC",       phone: "(248) 555-0122", email: "contracts@apexcorp.com"),
                          Party(name: "Rivera Design Studio", phone: "(248) 555-0399", email: "hello@riveradesign.com")),
            .nda:        (Party(name: "TechVault Inc.",      phone: "(248) 555-0177", email: "legal@techvault.com"),
                          Party(name: "Alex Patel",          phone: "(248) 555-0244", email: "alex.patel@email.com")),
            .bill:       (Party(name: "David Okonkwo",      phone: "(313) 555-0133", email: "david.ok@email.com"),
                          Party(name: "Lisa Chen",           phone: "(313) 555-0291", email: "lchen@email.com")),
            .contractor: (Party(name: "Nova Solutions LLC",  phone: "(248) 555-0166", email: "ops@novasolutions.com"),
                          Party(name: "James Oduya",         phone: "(248) 555-0388", email: "james.oduya@email.com")),
        ]
        for (type, (p1, p2)) in defaults {
            party1[type.rawValue] = p1
            party2[type.rawValue] = p2
        }
    }

    var currentParty1: Party {
        get { party1[activeType.rawValue] ?? Party(name: "", phone: "", email: "") }
        set { party1[activeType.rawValue] = newValue }
    }

    var currentParty2: Party {
        get { party2[activeType.rawValue] ?? Party(name: "", phone: "", email: "") }
        set { party2[activeType.rawValue] = newValue }
    }

    func contractId(for type: ContractTypeID) -> String {
        if let existing = contractIds[type.rawValue] { return existing }
        let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let rand = { String((0..<4).map { _ in chars.randomElement()! }) }
        let id = "\(type.prefix)-\(rand())-\(rand())"
        contractIds[type.rawValue] = id
        return id
    }

    var currentContractId: String { contractId(for: activeType) }

    func switchType(_ type: ContractTypeID) {
        activeType = type
        chatMessages = []
    }

    // ── AI Review ──
    @MainActor
    func sendAIMessage(_ userText: String) async {
        guard !userText.trimmingCharacters(in: .whitespaces).isEmpty, !isSampling else { return }
        let contractText = contractPlainText()
        chatMessages.append(ChatMessage(role: .user, text: userText))
        chatMessages.append(ChatMessage(role: .assistant, text: ""))
        isSampling = true

        await callClaude(userText: userText, contractText: contractText)

        isSampling = false
    }

    private func contractPlainText() -> String {
        let p1 = currentParty1
        let p2 = currentParty2
        switch activeType {
        case .loan:
            let s = loanState
            let n = periodsForSchedule(s.schedule)
            let p = calcPayment(principal: Double(s.amount) ?? 0, annualRate: Double(s.rate) ?? 0, periods: n, schedule: s.schedule)
            return "LOAN AGREEMENT | \(activeType.party1Label): \(p1.name) | \(activeType.party2Label): \(p2.name) | Principal: \(formatCurrency(Double(s.amount) ?? 0)) | Rate: \(s.rate)% | Schedule: \(s.schedule) | Purpose: \(s.purpose) | Payment: \(formatCurrency(p)) | Governing State: \(s.govState)"
        case .lease:
            let s = leaseState
            return "LEASE AGREEMENT | \(activeType.party1Label): \(p1.name) | \(activeType.party2Label): \(p2.name) | Property: \(s.property) | Rent: \(formatCurrency(Double(s.rent) ?? 0))/mo | Deposit: \(formatCurrency(Double(s.deposit) ?? 0)) | Term: \(s.term) months from \(s.startDate) | Pets: \(s.petsAllowed ? "Yes" : "No") | Governing State: \(s.govState)"
        case .service:
            let s = serviceState
            return "SERVICE AGREEMENT | \(activeType.party1Label): \(p1.name) | \(activeType.party2Label): \(p2.name) | Services: \(s.serviceDesc) | Fee: \(formatCurrency(Double(s.totalFee) ?? 0)) | Payment: \(s.payTerms) | \(s.startDate) to \(s.endDate) | Governing State: \(s.govState)"
        case .nda:
            let s = ndaState
            return "NDA | \(activeType.party1Label): \(p1.name) | \(activeType.party2Label): \(p2.name) | Purpose: \(s.purpose) | Duration: \(s.period) years | Type: \(s.relType) | Governing State: \(s.govState)"
        case .bill:
            let s = billState
            return "BILL OF SALE | \(activeType.party1Label): \(p1.name) | \(activeType.party2Label): \(p2.name) | Item: \(s.itemDesc) | Price: \(formatCurrency(Double(s.salePrice) ?? 0)) | Condition: \(s.condition) | Date: \(s.saleDate) | Governing State: \(s.govState)"
        case .contractor:
            let s = contractorState
            let comp = s.rateType == "hourly" ? "\(formatCurrency(Double(s.rate2) ?? 0))/hr" : formatCurrency(Double(s.rate2) ?? 0)
            return "INDEPENDENT CONTRACTOR AGREEMENT | \(activeType.party1Label): \(p1.name) | \(activeType.party2Label): \(p2.name) | Services: \(s.servDesc) | Compensation: \(comp) | \(s.startDate) to \(s.endDate) | Governing State: \(s.govState)"
        }
    }

    @MainActor
    private func callClaude(userText: String, contractText: String) async {
        let key = anthropicAPIKey
        guard !key.isEmpty else {
            chatMessages[chatMessages.count - 1].text = "⚙️ Add your Anthropic API key in ContractViewModel.swift (anthropicAPIKey property) to enable AI Review."
            return
        }
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        req.setValue(key, forHTTPHeaderField: "x-api-key")

        let systemPrompt = "You are a helpful legal contract assistant. Be concise and clear. Use **bold** for key terms. Max 250 words."
        let prevMsgs = chatMessages.dropLast()
        var apiMessages: [[String: String]] = []
        // First user message: embed contract context
        if let first = prevMsgs.first(where: { $0.role == .user }) {
            apiMessages.append(["role": "user", "content": "\(systemPrompt)\n\nCONTRACT:\n\(contractText)\n\nQUESTION: \(first.text)"])
            var skippedFirst = false
            for m in prevMsgs.dropFirst() {
                _ = skippedFirst
                apiMessages.append(["role": m.role == .assistant ? "assistant" : "user", "content": m.text])
            }
        }

        let body: [String: Any] = [
            "model": "claude-opus-4-5",
            "max_tokens": 512,
            "stream": true,
            "messages": apiMessages
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (bytes, _) = try await URLSession.shared.bytes(for: req)
            var accumulated = ""
            for try await line in bytes.lines {
                guard line.hasPrefix("data: ") else { continue }
                let data = String(line.dropFirst(6))
                guard data != "[DONE]",
                      let d = data.data(using: .utf8),
                      let json = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
                      let type_ = json["type"] as? String else { continue }
                if type_ == "content_block_delta",
                   let delta = json["delta"] as? [String: Any],
                   let text = delta["text"] as? String {
                    accumulated += text
                    chatMessages[chatMessages.count - 1].text = accumulated
                }
            }
        } catch {
            chatMessages[chatMessages.count - 1].text = "Error: \(error.localizedDescription)"
        }
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    var role: ChatRole
    var text: String
    enum ChatRole { case user, assistant }
}
