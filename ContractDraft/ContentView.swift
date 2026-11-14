import SwiftUI

struct ContentView: View {
    @StateObject private var vm = ContractViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Top bar
            topBar
            // Type selector
            typeStrip
            // Tab content
            tabContent
            // Bottom nav
            bottomNav
        }
        .background(Color(.systemGroupedBackground))
        .ignoresSafeArea(edges: .bottom)
    }

    private var topBar: some View {
        HStack {
            Text("ContractDraft")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Spacer()
            Text(vm.currentContractId)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.75))
                .monospacedDigit()
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 12)
        .background(Color.accentColor)
    }

    private var typeStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(ContractTypeID.allCases) { type in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            vm.switchType(type)
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Text(type.emoji).font(.system(size: 13))
                            Text(type.label).font(.system(size: 11.5, weight: .semibold))
                        }
                        .padding(.horizontal, 11)
                        .padding(.vertical, 5)
                        .background(vm.activeType == type ? Color.white : Color.white.opacity(0.12))
                        .foregroundColor(vm.activeType == type ? Color.accentColor : .white.opacity(0.85))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
        }
        .background(Color.accentColor.opacity(0.85))
    }

    @ViewBuilder
    private var tabContent: some View {
        switch vm.activeTab {
        case 0: DetailsView(vm: vm)
        case 1: ContractPreviewView(vm: vm)
        case 2: SendView(vm: vm)
        case 3: AIReviewView(vm: vm)
        default: EmptyView()
        }
    }

    private var bottomNav: some View {
        HStack(spacing: 0) {
            navTab(index: 0, icon: "doc.text", label: "Details")
            navTab(index: 1, icon: "doc.plaintext", label: "Contract")
            navTab(index: 2, icon: "paperplane", label: "Send")
            navTab(index: 3, icon: "sparkles", label: "AI Review")
        }
        .background(Color(.systemBackground))
        .overlay(Rectangle().frame(height: 0.5).foregroundColor(Color(.separator)), alignment: .top)
        .padding(.bottom, 0)
    }

    private func navTab(index: Int, icon: String, label: String) -> some View {
        Button { vm.activeTab = index } label: {
            VStack(spacing: 3) {
                Image(systemName: vm.activeTab == index ? icon + ".fill" : icon)
                    .font(.system(size: 20))
                    .symbolRenderingMode(.hierarchical)
                Circle()
                    .frame(width: 4, height: 4)
                    .opacity(vm.activeTab == index ? 1 : 0)
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(vm.activeTab == index ? .accentColor : Color(.secondaryLabel))
            .frame(maxWidth: .infinity)
            .padding(.top, 10)
            .padding(.bottom, 16)
        }
        .buttonStyle(.plain)
    }
}
