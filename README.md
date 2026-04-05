
> **Automated UI Testing for FastPay Agent Android App using Maestro**

---

## ✨ Features Tested

| # | Feature | File |
|---|---------|------|
| 1 | 🔐 Login | `Login.yaml` |
| 2 | 💰 Sell Balance | `Sell Balance.yaml` |
| 3 | 💸 Transfer Money | `Transfer Money.yaml` |

---

## ⚠️ Important Note

> **If any flow fails, all subsequent flows will stop immediately.**
>
> Example:
> ```
> ✅ Login        → Passed
> ❌ Sell Balance → Failed  → Execution stops here!
> ⏭️ Transfer Money → Never runs
> ```
> Fix the failed flow first, then re-run the tests.

---

## 📁 Project Structure
📦 FastPay Agent/
├── 📄 BaseFile.yaml
├── 📄 Login.yaml
├── 📄 Sell Balance.yaml
├── 📄 Transfer Money.yaml
├── ⚙️ run_and_report.ps1
└── 📊 reports/
└── TestReport_2026-04-05_14-30-22.html


---

## 🛠️ Prerequisites
✅ Install Maestro → https://maestro.mobile.dev/
✅ Install ADB → https://developer.android.com/tools/releases/platform-tools
✅ Enable USB Debugging on Android device
✅ Connect device via USB



Verify everything:
```powershell
maestro -v
adb devices
⚙️ Setup Credentials

Open run_and_report.ps1 and update:

PowerShell

$User     = "YOUR_MOBILE_NUMBER"
$Password = "YOUR_PASSWORD"
$Customer = "CUSTOMER_MOBILE_NUMBER"
$Agent    = "AGENT_MOBILE_NUMBER"
🚀 Run Tests + Generate Report
Run this single command in PowerShell:

PowerShell

powershell -ExecutionPolicy Bypass -File "C:\Maestro Project\Practice Project\FastPay Agent\run_and_report.ps1"
✅ Runs all tests on your Android device
✅ Generates HTML report automatically
✅ Opens report in browser
✅ Saves report in reports/ folder with timestamp

📊 Sample Report Output
text

========================================
       TEST RESULTS SUMMARY
========================================
  ✅ PASS : Login          - Successful
  ✅ PASS : Sell Balance   - Successful
  ✅ PASS : Transfer Money - Successful

  Total    : 3
  Passed   : 3
  Failed   : 0
  Duration : 71.3s
========================================

## 📌 Quick Rules



| &nbsp; | ✅ **DO** | ❌ **DON'T** |
|:------:|-----------|--------------|
| 📱 | Keep device screen **ON** | Touch device during tests |
| 🔌 | Connect via **USB cable** | Use wireless if unstable |
| 🔍 | Run `adb devices` **before** starting | Skip device connection check |
| 🐛 | **Fix** the failed flow before re-run | Ignore flow errors |
| 🔒 | Use **test/staging** accounts only | Use production credentials |
| 🔓 | Keep device **unlocked** during tests | Let screen auto-lock |
| 📂 | Keep all **YAML files** intact | Delete or rename YAML files |
| ⏸️ | Wait for tests to **fully complete** | Interrupt tests midway |

</div>
