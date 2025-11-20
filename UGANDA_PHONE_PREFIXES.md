# Uganda Mobile Money Phone Number Prefixes

## ✅ Verified Complete List

### MTN Uganda (MTN_MOMO_UGA)
- **077** - Original MTN prefix
- **078** - MTN expansion prefix
- **076** - MTN additional prefix
- **079** - MTN newest prefix
- **031** - MTN special prefix
- **039** - MTN special prefix

**Total: 6 prefixes**

### Airtel Uganda (AIRTEL_OAPI_UGA)
- **070** - Primary Airtel prefix
- **074** - Airtel expansion prefix
- **075** - Airtel additional prefix

**Total: 3 prefixes**

---

## 📱 Valid Phone Number Formats

### Accepted Formats:
1. `0XXXXXXXXX` (10 digits) - e.g., `0772123456`
2. `+256XXXXXXXXX` (13 characters) - e.g., `+256772123456`
3. `256XXXXXXXXX` (12 digits) - e.g., `256772123456`

### Examples:
- ✅ `0772123456` → MTN
- ✅ `+256772123456` → MTN
- ✅ `0700123456` → Airtel
- ✅ `+256700123456` → Airtel
- ✅ `0313456789` → MTN (031 prefix)
- ✅ `0763456789` → MTN (076 prefix)
- ✅ `0793456789` → MTN (079 prefix)

---

## 🔧 Implementation Details

### Code Location:
- **Operator Detection:** `lib/services/pawapay_service.dart` (lines 62-93)
- **Phone Validation:** `lib/services/pawapay_service.dart` (lines 95-106)
- **UI Helper Text:** `lib/screens/shg/subscription_purchase_screen.dart`
- **PawaPay Config:** `lib/config/pawapay_config.dart`

### Correspondent Mapping:
```dart
MTN prefixes (077, 078, 076, 079, 031, 039) → 'MTN_MOMO_UGA'
Airtel prefixes (070, 074, 075) → 'AIRTEL_OAPI_UGA'
```

### PawaPay API Parameters:
```json
{
  "country": "UGA",
  "currency": "UGX",
  "correspondent": "MTN_MOMO_UGA" or "AIRTEL_OAPI_UGA",
  "payer": {
    "type": "MSISDN",
    "address": {
      "value": "+256XXXXXXXXX"
    }
  }
}
```

---

## 📊 Coverage Status

### ✅ Fully Supported:
- All 6 MTN Uganda prefixes
- All 3 Airtel Uganda prefixes
- International format (+256)
- Local format (0XXX)

### ❌ Not Supported:
- Other operators (Africell, Uganda Telecom, etc.)
- Non-Uganda phone numbers

---

## 🧪 Testing Checklist

Test with these sample numbers:
- [ ] MTN 077: `0772123456`
- [ ] MTN 078: `0782123456`
- [ ] MTN 076: `0762123456`
- [ ] MTN 079: `0792123456`
- [ ] MTN 031: `0312123456`
- [ ] MTN 039: `0392123456`
- [ ] Airtel 070: `0702123456`
- [ ] Airtel 074: `0742123456`
- [ ] Airtel 075: `0752123456`

**Expected:** Operator badge appears next to phone input, mobile money prompt reaches phone.

---

## 📝 References

- **PawaPay Documentation:** https://docs.pawapay.io/
- **Uganda Mobile Operators:** MTN Uganda, Airtel Uganda
- **Firebase Console:** https://console.firebase.google.com/project/sayekataleapp
- **GitHub Repository:** https://github.com/DrakeNamanya/sayekataleapp

**Last Updated:** November 20, 2025  
**Version:** 1.0.0
