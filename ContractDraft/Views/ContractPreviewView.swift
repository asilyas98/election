import SwiftUI

struct ContractPreviewView: View {
    @ObservedObject var vm: ContractViewModel
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                contractContent
                signatureBlock
            }
            .padding(18)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(.separator), lineWidth: 0.5))
            .padding(12)
        }
    }

    @ViewBuilder private var contractContent: some View {
        Group {
            switch vm.activeType {
            case .loan:    loanContract
            case .lease:   leaseContract
            case .service: serviceContract
            case .nda:     ndaContract
            case .bill:    billContract
            case .contractor: contractorContract
            }
        }
    }

    private var loanContract: some View {
        let s = vm.loanState
        let p1 = vm.currentParty1.name.isEmpty ? "[Lender]" : vm.currentParty1.name
        let p2 = vm.currentParty2.name.isEmpty ? "[Borrower]" : vm.currentParty2.name
        let n = periodsForSchedule(s.schedule)
        let pmt = calcPayment(principal: Double(s.amount) ?? 0, annualRate: Double(s.rate) ?? 0, periods: n, schedule: s.schedule)
        let total = pmt * Double(n)
        let lbl = s.schedule == "monthly" ? "monthly" : s.schedule == "biweekly" ? "bi-weekly" : "weekly"
        return contractBody(title: "PERSONAL LOAN AGREEMENT", id: vm.currentContractId, clauses: [
            ("1. Loan Amount", "Lender \(p1) agrees to loan Borrower \(p2) the principal sum of \(formatCurrency(Double(s.amount) ?? 0)). Borrower acknowledges receipt of these funds."),
            ("2. Interest Rate", "The outstanding principal shall bear interest at \(s.rate)% per annum, calculated on a simple interest basis."),
            ("3. Repayment Schedule", "Borrower shall repay in \(n) \(lbl) payments of \(formatCurrency(pmt)) each, totaling \(formatCurrency(total)). First payment is due one full payment period from the date hereof."),
            ("4. Purpose", "Loan proceeds shall be used exclusively for: \(s.purpose). Unauthorized use constitutes a material breach."),
            ("5. Prepayment", "Borrower may prepay any portion of the outstanding balance at any time without penalty."),
            ("6. Default", "Borrower is in default if any payment is not received within 10 days of its due date, making the entire balance immediately due at Lender's discretion."),
            ("7. Governing Law", "This Agreement is governed by the laws of \(s.govState)."),
        ])
    }

    private var leaseContract: some View {
        let s = vm.leaseState
        let p1 = vm.currentParty1.name.isEmpty ? "[Landlord]" : vm.currentParty1.name
        let p2 = vm.currentParty2.name.isEmpty ? "[Tenant]" : vm.currentParty2.name
        let endDate = addMonths(s.startDate, Int(s.term) ?? 12)
        return contractBody(title: "RESIDENTIAL LEASE AGREEMENT", id: vm.currentContractId, clauses: [
            ("1. Premises", "Landlord \(p1) hereby leases to Tenant \(p2) the property at: \(s.property), for residential use only."),
            ("2. Lease Term", "Lease commences \(s.startDate) and expires \(endDate) (\(s.term) months). Continued occupancy converts to month-to-month."),
            ("3. Rent", "Tenant shall pay \(formatCurrency(Double(s.rent) ?? 0))/month, due on the 1st. Rent not received by the 5th is subject to a 5% late fee."),
            ("4. Security Deposit", "Tenant shall deposit \(formatCurrency(Double(s.deposit) ?? 0)), refundable within 30 days of vacancy less any deductions for damages beyond normal wear and tear."),
            ("5. Maintenance", "Tenant shall maintain the Premises and report damage promptly. Landlord maintains all major systems (HVAC, plumbing, electrical)."),
            ("6. Pets", s.petsAllowed ? "Pets are permitted with prior written approval from Landlord. A pet deposit may be required." : "No pets are permitted without prior written consent from Landlord."),
            ("7. Termination", "Either party may terminate month-to-month tenancy with 30 days notice. Early termination of fixed term requires 60 days notice."),
            ("8. Governing Law", "This Agreement is governed by the laws of \(s.govState)."),
        ])
    }

    private var serviceContract: some View {
        let s = vm.serviceState
        let p1 = vm.currentParty1.name.isEmpty ? "[Client]" : vm.currentParty1.name
        let p2 = vm.currentParty2.name.isEmpty ? "[Provider]" : vm.currentParty2.name
        let ptText = s.payTerms == "upfront" ? "100% due upon signing." : s.payTerms == "milestone" ? "50% due upon signing; 50% upon completion." : "100% due upon project completion."
        return contractBody(title: "SERVICE AGREEMENT", id: vm.currentContractId, clauses: [
            ("1. Scope of Services", "Service Provider \(p2) agrees to perform for Client \(p1): \(s.serviceDesc). Services shall be delivered in a professional manner."),
            ("2. Project Timeline", "Work commences \(s.startDate) and is expected by \(s.endDate). Delays caused by Client's failure to provide materials extend the timeline accordingly."),
            ("3. Compensation", "Client agrees to pay \(formatCurrency(Double(s.totalFee) ?? 0)). \(ptText) Invoices due within 15 days of receipt."),
            ("4. Independent Contractor", "Service Provider is an independent contractor, not an employee, and is solely responsible for all taxes and insurance."),
            ("5. Intellectual Property", "Upon full payment, all deliverables become Client's property. Provider retains the right to display work in portfolio."),
            ("6. Revisions", "Up to two (2) rounds of revisions included. Additional revisions billed at an agreed hourly rate."),
            ("7. Termination", "Either party may terminate with 14 days written notice. Client pays for all work completed to date."),
            ("8. Governing Law", "This Agreement is governed by the laws of \(s.govState)."),
        ])
    }

    private var ndaContract: some View {
        let s = vm.ndaState
        let p1 = vm.currentParty1.name.isEmpty ? "[Disclosing Party]" : vm.currentParty1.name
        let p2 = vm.currentParty2.name.isEmpty ? "[Receiving Party]" : vm.currentParty2.name
        return contractBody(title: "NON-DISCLOSURE AGREEMENT", id: vm.currentContractId, clauses: [
            ("1. Purpose", "This NDA is entered into in connection with: \(s.purpose). The parties wish to explore potential business collaboration."),
            ("2. Confidential Information", "Receiving Party \(p2) agrees to hold all non-public information disclosed by \(p1) in strict confidence and not disclose it to third parties."),
            ("3. Exceptions", "Confidential information excludes: (a) information already public; (b) information known prior to disclosure; (c) information independently developed; (d) information required by law to be disclosed."),
            ("4. Duration", "Obligations of confidentiality shall remain in effect for \(s.period) years from the date of this Agreement."),
            ("5. Return of Information", "Upon request, Receiving Party shall promptly return or destroy all confidential materials."),
            ("6. Remedies", "Breach may cause irreparable harm. Disclosing Party is entitled to seek injunctive relief without the need to post bond, in addition to other remedies."),
            ("7. Governing Law", "This Agreement is governed by the laws of \(s.govState)."),
        ])
    }

    private var billContract: some View {
        let s = vm.billState
        let p1 = vm.currentParty1.name.isEmpty ? "[Seller]" : vm.currentParty1.name
        let p2 = vm.currentParty2.name.isEmpty ? "[Buyer]" : vm.currentParty2.name
        let cond = s.condition == "as-is" ? "AS-IS, with no warranties express or implied" : s.condition.capitalized
        return contractBody(title: "BILL OF SALE", id: vm.currentContractId, clauses: [
            ("1. Sale of Property", "Seller \(p1) agrees to sell and Buyer \(p2) agrees to purchase the following: \(s.itemDesc)."),
            ("2. Purchase Price", "Buyer agrees to pay \(formatCurrency(Double(s.salePrice) ?? 0)) as full and complete consideration for the item described herein."),
            ("3. Condition", "The item is sold in \(cond) condition."),
            ("4. Transfer of Ownership", "Seller warrants that they are the lawful owner with the right to sell the item, free and clear of all liens and encumbrances."),
            ("5. Date of Sale", "This sale is effective as of \(s.saleDate). Risk of loss passes to Buyer upon transfer."),
            ("6. Payment", "Payment shall be made in full at the time of transfer unless otherwise agreed in writing by both parties."),
            ("7. Governing Law", "This Bill of Sale is governed by the laws of \(s.govState)."),
        ])
    }

    private var contractorContract: some View {
        let s = vm.contractorState
        let p1 = vm.currentParty1.name.isEmpty ? "[Company]" : vm.currentParty1.name
        let p2 = vm.currentParty2.name.isEmpty ? "[Contractor]" : vm.currentParty2.name
        let comp = s.rateType == "fixed" ? "a fixed fee of \(formatCurrency(Double(s.rate2) ?? 0)) for the full engagement" : "an hourly rate of \(formatCurrency(Double(s.rate2) ?? 0))/hour, invoiced bi-weekly"
        return contractBody(title: "INDEPENDENT CONTRACTOR AGREEMENT", id: vm.currentContractId, clauses: [
            ("1. Services", "Contractor \(p2) agrees to perform for Company \(p1): \(s.servDesc)."),
            ("2. Term", "This Agreement begins \(s.startDate) and continues through \(s.endDate) unless earlier terminated."),
            ("3. Compensation", "Company shall pay Contractor \(comp). Invoices due within 15 days. Late payments accrue interest at 1.5%/month."),
            ("4. Independent Contractor Status", "Contractor is an independent contractor, not an employee, and is solely responsible for all self-employment taxes and insurance."),
            ("5. Confidentiality", "Contractor shall hold all proprietary Company information in strict confidence during and after this engagement."),
            ("6. Intellectual Property", "All work product created specifically for Company is work made for hire and is Company's sole property upon full payment."),
            ("7. Termination", "Either party may terminate with 14 days written notice. Sections 5 and 6 survive termination."),
            ("8. Governing Law", "This Agreement is governed by the laws of \(s.govState)."),
        ])
    }

    func contractBody(title: String, id: String, clauses: [(String, String)]) -> some View {
        VStack(alignment: .center, spacing: 0) {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .padding(.bottom, 2)
            Text("Contract ID: \(id)  ·  \(fmtDate())")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Color(.tertiaryLabel))
                .padding(.bottom, 16)

            let p1 = vm.currentParty1.name.isEmpty ? "[\(vm.activeType.party1Label)]" : vm.currentParty1.name
            let p2 = vm.currentParty2.name.isEmpty ? "[\(vm.activeType.party2Label)]" : vm.currentParty2.name
            Text("This \(title.capitalized) is entered into as of \(fmtDate()), by and between **\(p1)** ("\(vm.activeType.party1Label)") and **\(p2)** ("\(vm.activeType.party2Label)").")
                .font(.system(size: 12))
                .foregroundColor(Color(.label))
                .lineSpacing(3)
                .padding(.bottom, 10)

            ForEach(clauses, id: \.0) { clause in
                VStack(alignment: .leading, spacing: 3) {
                    Text(clause.0)
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundColor(.accentColor)
                        .kerning(0.5)
                        .textCase(.uppercase)
                    Text(clause.1)
                        .font(.system(size: 12))
                        .foregroundColor(Color(.label))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 10)
            }
        }
    }

    private var signatureBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
            Text("SIGNATURES")
                .font(.system(size: 10.5, weight: .bold))
                .foregroundColor(.accentColor)
                .kerning(0.5)
            HStack(spacing: 20) {
                sigItem(label: vm.activeType.party1Label, name: vm.currentParty1.name)
                sigItem(label: vm.activeType.party2Label, name: vm.currentParty2.name)
            }
            HStack(spacing: 20) {
                sigItem(label: "DATE", name: "")
                sigItem(label: "DATE", name: "")
            }
            .padding(.top, 10)
        }
        .padding(.top, 10)
    }

    private func sigItem(label: String, name: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Rectangle().frame(height: 26).foregroundColor(.clear)
                .overlay(Rectangle().frame(height: 1).foregroundColor(Color(.separator)), alignment: .bottom)
            Text("\(label)\(name.isEmpty ? "" : " — \(name)")")
                .font(.system(size: 9.5, weight: .medium))
                .foregroundColor(Color(.tertiaryLabel))
        }
        .frame(maxWidth: .infinity)
    }
}
