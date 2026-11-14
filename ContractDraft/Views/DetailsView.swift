import SwiftUI

struct DetailsView: View {
    @ObservedObject var vm: ContractViewModel
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                partySection(label: vm.activeType.party1Label,
                    name: Binding(get: { vm.currentParty1.name }, set: { vm.party1[vm.activeType.rawValue]?.name = $0 }),
                    phone: Binding(get: { vm.currentParty1.phone }, set: { vm.party1[vm.activeType.rawValue]?.phone = $0 }),
                    email: Binding(get: { vm.currentParty1.email }, set: { vm.party1[vm.activeType.rawValue]?.email = $0 })
                )
                partySection(label: vm.activeType.party2Label,
                    name: Binding(get: { vm.currentParty2.name }, set: { vm.party2[vm.activeType.rawValue]?.name = $0 }),
                    phone: Binding(get: { vm.currentParty2.phone }, set: { vm.party2[vm.activeType.rawValue]?.phone = $0 }),
                    email: Binding(get: { vm.currentParty2.email }, set: { vm.party2[vm.activeType.rawValue]?.email = $0 })
                )
                typeSpecificFields
                summaryBand
                Spacer(minLength: 24)
            }
        }
    }

    @ViewBuilder private var typeSpecificFields: some View {
        SectionHeader("Terms")
        switch vm.activeType {
        case .loan:    LoanFields(s: $vm.loanState)
        case .lease:   LeaseFields(s: $vm.leaseState)
        case .service: ServiceFields(s: $vm.serviceState)
        case .nda:     NDAFields(s: $vm.ndaState)
        case .bill:    BillFields(s: $vm.billState)
        case .contractor: ContractorFields(s: $vm.contractorState)
        }
    }

    @ViewBuilder private var summaryBand: some View {
        VStack(spacing: 0) {
            switch vm.activeType {
            case .loan:
                let s = vm.loanState
                let n = periodsForSchedule(s.schedule)
                let p = calcPayment(principal: Double(s.amount) ?? 0, annualRate: Double(s.rate) ?? 0, periods: n, schedule: s.schedule)
                let total = p * Double(n)
                SummaryBand(rows: [
                    ("\(s.schedule.capitalized) Payment", formatCurrency(p)),
                    nil,
                    ("Total Interest", formatCurrency(total - (Double(s.amount) ?? 0))),
                    ("Total Due", formatCurrency(total)),
                ])
            case .lease:
                let s = vm.leaseState
                SummaryBand(rows: [
                    ("Monthly Rent", formatCurrency(Double(s.rent) ?? 0)),
                    nil,
                    ("Security Deposit", formatCurrency(Double(s.deposit) ?? 0)),
                    ("Lease Term", "\(s.term) months"),
                ])
            case .service:
                let s = vm.serviceState
                let pt = s.payTerms == "upfront" ? "100% Upfront" : s.payTerms == "milestone" ? "Milestone" : "On Completion"
                SummaryBand(rows: [
                    ("Total Fee", formatCurrency(Double(s.totalFee) ?? 0)),
                    nil,
                    ("Payment", pt),
                    ("Period", "\(s.startDate) → \(s.endDate)"),
                ])
            case .nda:
                let s = vm.ndaState
                SummaryBand(rows: [
                    ("Duration", "\(s.period) years"),
                    nil,
                    ("Relationship", s.relType.capitalized),
                    ("Mutual Obligation", "Both parties bound"),
                ])
            case .bill:
                let s = vm.billState
                SummaryBand(rows: [
                    ("Sale Price", formatCurrency(Double(s.salePrice) ?? 0)),
                    nil,
                    ("Condition", s.condition.capitalized),
                    ("Sale Date", s.saleDate),
                ])
            case .contractor:
                let s = vm.contractorState
                let rateLabel = s.rateType == "hourly" ? "Hourly Rate" : "Fixed Fee"
                let rateVal = s.rateType == "hourly" ? formatCurrency(Double(s.rate2) ?? 0) + "/hr" : formatCurrency(Double(s.rate2) ?? 0)
                SummaryBand(rows: [
                    (rateLabel, rateVal),
                    nil,
                    ("Start", s.startDate),
                    ("End", s.endDate),
                ])
            }
        }
    }

    private func partySection(label: String, name: Binding<String>, phone: Binding<String>, email: Binding<String>) -> some View {
        VStack(spacing: 0) {
            SectionHeader(label)
            FormCard {
                FormField(icon: "person", label: "Full Name / Entity", text: name, keyboard: .default)
                Divider().padding(.leading, 58)
                FormField(icon: "phone", label: "Phone", text: phone, keyboard: .phonePad)
                Divider().padding(.leading, 58)
                FormField(icon: "envelope", label: "Email", text: email, keyboard: .emailAddress)
            }
        }
    }
}

// ── Type-specific field views ──
struct LoanFields: View {
    @Binding var s: LoanState
    var body: some View {
        FormCard {
            FormField(icon: "dollarsign.circle", label: "Principal Amount", text: $s.amount, keyboard: .decimalPad)
            Divider().padding(.leading, 58)
            FormField(icon: "percent", label: "Annual Interest Rate (%)", text: $s.rate, keyboard: .decimalPad)
            Divider().padding(.leading, 58)
            FormField(icon: "tag", label: "Purpose of Loan", text: $s.purpose, keyboard: .default)
            Divider().padding(.leading, 58)
            SegmentRow(label: "Schedule", selection: $s.schedule,
                       options: [("Monthly","monthly"),("Bi-Weekly","biweekly"),("Weekly","weekly")])
        }
        FormCard {
            FormField(icon: "map", label: "Governing State", text: $s.govState, keyboard: .default)
        }
    }
}

struct LeaseFields: View {
    @Binding var s: LeaseState
    var body: some View {
        FormCard {
            FormField(icon: "house", label: "Property Address", text: $s.property, keyboard: .default)
            Divider().padding(.leading, 58)
            FormField(icon: "dollarsign.circle", label: "Monthly Rent ($)", text: $s.rent, keyboard: .decimalPad)
            Divider().padding(.leading, 58)
            FormField(icon: "shield", label: "Security Deposit ($)", text: $s.deposit, keyboard: .decimalPad)
            Divider().padding(.leading, 58)
            FormField(icon: "calendar", label: "Lease Start Date", text: $s.startDate, keyboard: .default)
            Divider().padding(.leading, 58)
            FormField(icon: "clock", label: "Lease Duration (months)", text: $s.term, keyboard: .numberPad)
            Divider().padding(.leading, 58)
            ToggleRow(label: "Pets Allowed", icon: "pawprint", isOn: $s.petsAllowed)
        }
        FormCard {
            FormField(icon: "map", label: "Governing State", text: $s.govState, keyboard: .default)
        }
    }
}

struct ServiceFields: View {
    @Binding var s: ServiceState
    var body: some View {
        FormCard {
            FormField(icon: "doc.text", label: "Scope of Services", text: $s.serviceDesc, keyboard: .default)
            Divider().padding(.leading, 58)
            FormField(icon: "dollarsign.circle", label: "Total Fee ($)", text: $s.totalFee, keyboard: .decimalPad)
            Divider().padding(.leading, 58)
            SegmentRow(label: "Payment Terms", selection: $s.payTerms,
                       options: [("Upfront","upfront"),("Milestone","milestone"),("On Completion","completion")])
            Divider().padding(.leading, 58)
            FormField(icon: "calendar", label: "Start Date", text: $s.startDate, keyboard: .default)
            Divider().padding(.leading, 58)
            FormField(icon: "calendar", label: "End Date", text: $s.endDate, keyboard: .default)
        }
        FormCard {
            FormField(icon: "map", label: "Governing State", text: $s.govState, keyboard: .default)
        }
    }
}

struct NDAFields: View {
    @Binding var s: NDAState
    var body: some View {
        FormCard {
            FormField(icon: "doc.text", label: "Purpose / Context", text: $s.purpose, keyboard: .default)
            Divider().padding(.leading, 58)
            FormField(icon: "clock", label: "Confidentiality Period (years)", text: $s.period, keyboard: .numberPad)
            Divider().padding(.leading, 58)
            SegmentRow(label: "Relationship Type", selection: $s.relType,
                       options: [("Business","business"),("Employment","employment"),("Contractor","contractor")])
        }
        FormCard {
            FormField(icon: "map", label: "Governing State", text: $s.govState, keyboard: .default)
        }
    }
}

struct BillFields: View {
    @Binding var s: BillState
    var body: some View {
        FormCard {
            FormField(icon: "tag", label: "Item Description", text: $s.itemDesc, keyboard: .default)
            Divider().padding(.leading, 58)
            FormField(icon: "dollarsign.circle", label: "Sale Price ($)", text: $s.salePrice, keyboard: .decimalPad)
            Divider().padding(.leading, 58)
            SegmentRow(label: "Condition", selection: $s.condition,
                       options: [("New","new"),("Used","used"),("As-Is","as-is")])
            Divider().padding(.leading, 58)
            FormField(icon: "calendar", label: "Sale Date", text: $s.saleDate, keyboard: .default)
        }
        FormCard {
            FormField(icon: "map", label: "Governing State", text: $s.govState, keyboard: .default)
        }
    }
}

struct ContractorFields: View {
    @Binding var s: ContractorState
    var body: some View {
        FormCard {
            FormField(icon: "doc.text", label: "Services Description", text: $s.servDesc, keyboard: .default)
            Divider().padding(.leading, 58)
            SegmentRow(label: "Rate Type", selection: $s.rateType, options: [("Hourly","hourly"),("Fixed","fixed")])
            Divider().padding(.leading, 58)
            FormField(icon: "dollarsign.circle",
                      label: s.rateType == "fixed" ? "Fixed Fee ($)" : "Hourly Rate ($)",
                      text: $s.rate2, keyboard: .decimalPad)
            Divider().padding(.leading, 58)
            FormField(icon: "calendar", label: "Start Date", text: $s.startDate, keyboard: .default)
            Divider().padding(.leading, 58)
            FormField(icon: "calendar", label: "End Date", text: $s.endDate, keyboard: .default)
        }
        FormCard {
            FormField(icon: "map", label: "Governing State", text: $s.govState, keyboard: .default)
        }
    }
}

// ── Shared Components ──
struct SectionHeader: View {
    let title: String
    init(_ title: String) { self.title = title }
    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.accentColor)
            .kerning(1.2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 6)
    }
}

struct FormCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        VStack(spacing: 0) { content }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
    }
}

struct FormField: View {
    let icon: String
    let label: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 30, height: 30)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.accentColor)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundColor(Color(.tertiaryLabel))
                TextField(label, text: $text)
                    .font(.system(size: 14))
                    .keyboardType(keyboard)
                    .autocorrectionDisabled()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
    }
}

struct ToggleRow: View {
    let label: String
    let icon: String
    @Binding var isOn: Bool
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 9).fill(Color.accentColor.opacity(0.12)).frame(width: 30, height: 30)
                Image(systemName: icon).font(.system(size: 13, weight: .medium)).foregroundColor(.accentColor)
            }
            Text(label).font(.system(size: 14))
            Spacer()
            Toggle("", isOn: $isOn).labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
    }
}

struct SegmentRow: View {
    let label: String
    @Binding var selection: String
    let options: [(String, String)] // (label, value)
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.system(size: 10.5, weight: .medium)).foregroundColor(Color(.tertiaryLabel))
                .padding(.horizontal, 16).padding(.top, 8)
            HStack(spacing: 2) {
                ForEach(options, id: \.1) { opt in
                    Button { selection = opt.1 } label: {
                        Text(opt.0)
                            .font(.system(size: 11, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(selection == opt.1 ? Color.accentColor : Color.clear)
                            .foregroundColor(selection == opt.1 ? .white : Color(.secondaryLabel))
                            .clipShape(RoundedRectangle(cornerRadius: 9))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(Color(.tertiarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }
}

struct SummaryBand: View {
    let rows: [(String, String)?]  // nil = divider
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<rows.count, id: \.self) { i in
                if let row = rows[i] {
                    HStack {
                        Text(row.0).font(.system(size: 12, weight: .medium)).foregroundColor(.white.opacity(0.85))
                        Spacer()
                        Text(row.1).font(.system(size: 15, weight: .bold)).foregroundColor(.white).monospacedDigit()
                    }
                    .padding(.vertical, 4.5)
                } else {
                    Divider().background(Color.white.opacity(0.2)).padding(.vertical, 4.5)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(LinearGradient(colors: [Color.accentColor, Color.accentColor.opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }
}
