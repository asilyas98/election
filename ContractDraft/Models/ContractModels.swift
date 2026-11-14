import Foundation

// MARK: - Shared Party
struct Party: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var phone: String
    var email: String
}

// MARK: - Contract Type Enum
enum ContractTypeID: String, CaseIterable, Identifiable {
    case loan, lease, service, nda, bill, contractor
    var id: String { rawValue }

    var label: String {
        switch self {
        case .loan: return "Loan"
        case .lease: return "Lease"
        case .service: return "Service"
        case .nda: return "NDA"
        case .bill: return "Bill of Sale"
        case .contractor: return "Contractor"
        }
    }
    var emoji: String {
        switch self {
        case .loan: return "💰"
        case .lease: return "🏠"
        case .service: return "🛠️"
        case .nda: return "🔒"
        case .bill: return "🏷️"
        case .contractor: return "📋"
        }
    }
    var prefix: String {
        switch self {
        case .loan: return "LN"
        case .lease: return "LS"
        case .service: return "SV"
        case .nda: return "ND"
        case .bill: return "BS"
        case .contractor: return "IC"
        }
    }
    var party1Label: String {
        switch self {
        case .loan: return "Lender"
        case .lease: return "Landlord"
        case .service: return "Client"
        case .nda: return "Disclosing Party"
        case .bill: return "Seller"
        case .contractor: return "Company"
        }
    }
    var party2Label: String {
        switch self {
        case .loan: return "Borrower"
        case .lease: return "Tenant"
        case .service: return "Provider"
        case .nda: return "Receiving Party"
        case .bill: return "Buyer"
        case .contractor: return "Contractor"
        }
    }
}

// MARK: - Per-type State
struct LoanState {
    var amount: String = "8500"
    var rate: String = "6.5"
    var purpose: String = "Home renovation"
    var schedule: String = "monthly" // monthly/biweekly/weekly
    var govState: String = "Michigan"
}

struct LeaseState {
    var property: String = "1428 Elm Street, Detroit, MI 48201"
    var rent: String = "1200"
    var deposit: String = "2400"
    var startDate: String = "2026-12-01"
    var term: String = "12"
    var petsAllowed: Bool = false
    var govState: String = "Michigan"
}

struct ServiceState {
    var serviceDesc: String = "Brand identity design and website development"
    var totalFee: String = "5000"
    var payTerms: String = "milestone" // upfront/milestone/completion
    var startDate: String = "2026-12-01"
    var endDate: String = "2027-03-01"
    var govState: String = "Michigan"
}

struct NDAState {
    var purpose: String = "Evaluation of potential business partnership"
    var period: String = "3"
    var relType: String = "business" // business/employment/contractor
    var govState: String = "Michigan"
}

struct BillState {
    var itemDesc: String = "2019 Toyota Camry, VIN 1HGBH41JXMN109186"
    var salePrice: String = "14500"
    var condition: String = "used" // new/used/as-is
    var saleDate: String = "2026-12-01"
    var govState: String = "Michigan"
}

struct ContractorState {
    var servDesc: String = "Full-stack web development and API integration"
    var rateType: String = "hourly" // hourly/fixed
    var rate2: String = "95"
    var startDate: String = "2026-12-01"
    var endDate: String = "2027-06-01"
    var govState: String = "Michigan"
}

// MARK: - Helpers
func formatCurrency(_ value: Double) -> String {
    let f = NumberFormatter()
    f.numberStyle = .currency
    f.currencyCode = "USD"
    return f.string(from: NSNumber(value: value)) ?? "$0.00"
}

func calcPayment(principal: Double, annualRate: Double, periods: Int, schedule: String) -> Double {
    guard principal > 0 else { return 0 }
    if annualRate == 0 { return principal / Double(periods) }
    let ppy: Double = schedule == "monthly" ? 12 : schedule == "biweekly" ? 26 : 52
    let r = annualRate / 100 / ppy
    let n = Double(periods)
    return principal * r * pow(1 + r, n) / (pow(1 + r, n) - 1)
}

func periodsForSchedule(_ s: String) -> Int {
    s == "monthly" ? 12 : s == "biweekly" ? 26 : 52
}

func fmtDate() -> String {
    let f = DateFormatter()
    f.dateStyle = .long
    return f.string(from: Date())
}

func addMonths(_ dateStr: String, _ months: Int) -> String {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    guard let d = f.date(from: dateStr) else { return "" }
    var c = DateComponents(); c.month = months
    return f.string(from: Calendar.current.date(byAdding: c, to: d) ?? d)
}
