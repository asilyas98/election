import SwiftUI

struct SendView: View {
    @ObservedObject var vm: ContractViewModel
    @State private var toast: String? = nil
    @State private var showToast = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                SectionHeader(vm.activeType.party1Label)
                contactCard(party: vm.currentParty1, role: vm.activeType.party1Label, color: .accentColor)
                SectionHeader(vm.activeType.party2Label)
                contactCard(party: vm.currentParty2, role: vm.activeType.party2Label, color: Color.blue)
                note
                Spacer(minLength: 24)
            }
        }
        .overlay(alignment: .bottom) {
            if showToast, let msg = toast {
                Text(msg)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16).padding(.vertical, 7)
                    .background(Color(.label))
                    .clipShape(Capsule())
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showToast)
    }

    private func contactCard(party: Party, role: String, color: Color) -> some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 10) {
                ZStack {
                    Circle().fill(color).frame(width: 36, height: 36)
                    Text(initials(party.name))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(party.name.isEmpty ? "—" : party.name)
                        .font(.system(size: 14, weight: .semibold))
                    Text(role.uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(color)
                        .kerning(0.3)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16).padding(.vertical, 11)
            .background(color.opacity(0.1))

            // Email row
            contactRow(icon: "envelope", value: party.email) {
                copyToClipboard(party.email)
            } onAction: {
                openEmail(party.email, role: role)
            }
            Divider().padding(.leading, 16)

            // Phone row
            contactRow(icon: "phone", value: party.phone) {
                copyToClipboard(party.phone)
            } onAction: {
                openSMS(party.phone)
            }

            // Action buttons
            HStack(spacing: 8) {
                actionButton("envelope.fill", label: "Email \(role)", color: color) { openEmail(party.email, role: role) }
                actionButton("message.fill", label: "SMS \(role)", color: .green) { openSMS(party.phone) }
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 12)
        .padding(.bottom, 10)
    }

    private func contactRow(icon: String, value: String, onCopy: @escaping () -> Void, onAction: @escaping () -> Void) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(Color(.tertiaryLabel))
                .frame(width: 20)
            Text(value.isEmpty ? "—" : value)
                .font(.system(size: 12.5))
            Spacer()
            Button { onCopy() } label: {
                Text("Copy")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 7))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16).padding(.vertical, 9)
    }

    private func actionButton(_ icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(label, systemImage: icon)
                .font(.system(size: 12.5, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(color.opacity(0.12))
                .foregroundColor(color)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private var note: some View {
        Text("Email and SMS open your native mail and messages apps with the full contract pre-loaded. Tap Copy to grab contact details.")
            .font(.system(size: 11.5))
            .foregroundColor(Color(.secondaryLabel))
            .lineSpacing(3)
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(Color.accentColor.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 12)
    }

    private func initials(_ name: String) -> String {
        let parts = name.split(separator: " ").map(String.init)
        return String(parts.prefix(2).compactMap({\.first}).map(String.init).joined()).uppercased().isEmpty ? "?" : String(parts.prefix(2).compactMap({\.first}).map(String.init).joined()).uppercased()
    }

    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
        showTemporaryToast("Copied!")
    }

    private func openEmail(_ email: String, role: String) {
        guard !email.isEmpty, let url = URL(string: "mailto:\(email)?subject=\(vm.activeType.label)%20Agreement%20–%20\(vm.currentContractId)") else {
            showTemporaryToast("No email provided"); return
        }
        UIApplication.shared.open(url)
    }

    private func openSMS(_ phone: String) {
        guard !phone.isEmpty else { showTemporaryToast("No phone provided"); return }
        let clean = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if let url = URL(string: "sms:\(clean)") { UIApplication.shared.open(url) }
    }

    private func showTemporaryToast(_ msg: String) {
        toast = msg; showToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showToast = false }
    }
}
