# ContractDraft — iOS Xcode Project

**6 contract types · AI Review · SwiftUI · iOS 16+**

## Setup

1. Open `ContractDraft.xcodeproj` in Xcode for local development.
2. The App Store bundle ID is `com.simpleai.contract`.
3. The `codemagic.yaml` release workflow uses Codemagic Code signing identities for this bundle ID and uploads builds to TestFlight.
4. In the Codemagic `contract` environment group, set `APP_STORE_CONNECT_PRIVATE_KEY`, `APP_STORE_CONNECT_KEY_IDENTIFIER`, and `APP_STORE_CONNECT_ISSUER_ID` to a matching, active Team API key.

## AI Review (Optional)

To enable the AI Review tab with real Claude responses:

1. Open `ViewModel/ContractViewModel.swift`
2. Find `var anthropicAPIKey: String = ""`
3. Set it to your Anthropic API key:
   ```swift
   var anthropicAPIKey: String = "sk-ant-your-key-here"
   ```

For production, store the key in Keychain, not source code.
Get an API key at: https://console.anthropic.com

## Features

- **Loan** — principal, interest, repayment schedule, payment calculator
- **Lease** — residential rental agreement with deposit and pet clause
- **Service** — scope of work, milestone/upfront/completion billing
- **NDA** — non-disclosure with configurable duration and relationship type
- **Bill of Sale** — sale of goods with condition and transfer of title
- **Contractor** — independent contractor with hourly or fixed rate

## App Store Submission

1. Set your Development Team
2. Product → Archive
3. Distribute App → App Store Connect
