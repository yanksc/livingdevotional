# RevenueCat App Store Setup

## Why the app crashed on archive/App Store

**Root cause:** The app was configured with a RevenueCat **Test Store** API key (`test_xxx`). RevenueCat explicitly states: *"Using a Test Store API key in production will crash your app."*

Test Store keys are for development only. They use a simulated store and must never be used for App Store builds.

## Fix: Use Production API key for Release/Archive

### 1. Get your Production (Apple) API key

1. Go to [RevenueCat Dashboard](https://app.revenuecat.com)
2. Open your project → **API Keys**
3. Find the **Apple** (iOS) **Public API key** — it does **NOT** start with `test_`
4. Do **not** use the Test Store key

### 2. Configure LocalSecrets for Release builds

1. If you don't have `LocalSecrets.xcconfig`:
   ```bash
   cp LocalSecrets.xcconfig.template LocalSecrets.xcconfig
   ```

2. Edit `LocalSecrets.xcconfig` and set your **Production** RevenueCat key:
   ```
   REVENUECAT_APPLE_API_KEY = your_apple_public_key_here
   ```

3. Add `HELICONE_API_KEY` if you use it (from the template).

### 3. RevenueCat Dashboard: Products and Offerings

Your log showed: *"Offering 'default' has no packages configured"*.

#### Step A: Import products

1. Go to [RevenueCat Dashboard](https://app.revenuecat.com) → your project
2. **Products** (in Product catalog) → **+ New** → **Import Products**
3. Select **App Store** and import `supporter_by_month_499` and `supporter_yearly_4999`
   - If Import doesn’t list them, use **+ New product** and add each by its exact Product ID

#### Step B: Link products to the "supporter" entitlement

1. Go to **Entitlements** → open or create the **supporter** entitlement (matches your code)
2. Attach both products (`supporter_by_month_499`, `supporter_yearly_4999`) to this entitlement
3. When a user purchases either product, they receive the "supporter" entitlement

#### Step C: Configure the default offering

1. Go to **Offerings** → open the **default** offering (create one if needed, then set it as your project’s Default Offering)
2. Click **+ Add package**
3. Add the **monthly** package:
   - **Identifier:** choose **$rc_monthly** (or `monthly`) from the dropdown
   - **Products:** attach `supporter_by_month_499`
4. Click **+ Add package** again
5. Add the **annual** package:
   - **Identifier:** choose **$rc_annual** (or `annual`)
   - **Products:** attach `supporter_yearly_4999`

These identifiers match what `SupporterService` expects: `offerings.current?.monthly` and `offerings.current?.annual`.

### Build configuration summary

| Build type   | Configuration | API key source       |
|-------------|---------------|----------------------|
| Simulator   | Debug         | `Debug.xcconfig` (Test key) |
| Archive/App Store | Release | `LocalSecrets.xcconfig` (Production key) |

Simulator builds continue to use the Test key. Archive and App Store builds use your Production key from `LocalSecrets.xcconfig`.

---

## Pre-archive verification checklist

Before archiving and submitting, verify:

### 1. LocalSecrets.xcconfig
- [ ] File exists (copy from template if needed)
- [ ] `REVENUECAT_APPLE_API_KEY` = your production key (starts with `appl_`, not `test_`)
- [ ] `HELICONE_API_KEY` set if you use AI features

### 2. RevenueCat dashboard
- [ ] P8 key uploaded (Project Settings → App Store Connect)
- [ ] Products imported: `supporter_by_month_499`, `supporter_yearly_4999`
- [ ] Entitlement **supporter** exists with both products attached
- [ ] Default offering has **monthly** and **annual** packages configured

### 3. App Store Connect
- [ ] Subscriptions have complete metadata (no "Missing Metadata")
- [ ] Products `supporter_by_month_499` and `supporter_yearly_4999` exist

### 4. Test before submitting
1. In Xcode: **Product → Scheme → Edit Scheme** → set **Run** to **Release**
2. Build and run on a **real device** (not simulator) — validates production RevenueCat key
3. Confirm app launches, offerings load, and paywall appears when expected
4. Switch scheme back to **Debug** for normal development
5. **Product → Archive** → Distribute to App Store Connect
