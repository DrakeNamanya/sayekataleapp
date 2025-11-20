# Uganda Mobile Money Numbers Reference

## ✅ Supported Mobile Money Operators

### 🟡 MTN Mobile Money Uganda
**Correspondent ID:** `MTN_MOMO_UGA`

**Supported Prefixes:**
- `077` - Original MTN prefix
- `078` - Original MTN prefix  
- `031` - Newer MTN prefix
- `039` - Newer MTN prefix
- `076` - Newer MTN prefix
- `079` - Newest MTN prefix

**Example Numbers:**
- `0772123456`
- `0783456789`
- `0313456789`
- `0393456789`
- `0763456789`
- `0793456789`

---

### 🔴 Airtel Money Uganda
**Correspondent ID:** `AIRTEL_OAPI_UGA`

**Supported Prefixes:**
- `070` - Original Airtel prefix
- `074` - Newer Airtel prefix
- `075` - Newer Airtel prefix

**Example Numbers:**
- `0702123456`
- `0743456789`
- `0753456789`

---

## 📱 Phone Number Formats Accepted

The app accepts all these formats:

1. **Local format:** `0XXXXXXXXX` (10 digits)
   - Example: `0772123456`

2. **International format:** `+256XXXXXXXXX` (13 characters)
   - Example: `+256772123456`

3. **International without +:** `256XXXXXXXXX` (12 digits)
   - Example: `256772123456`

---

## 🔧 Technical Implementation

### Operator Detection Logic

```dart
// MTN prefixes
if (prefix == '077' || prefix == '078' || prefix == '031' || 
    prefix == '039' || prefix == '076' || prefix == '079') {
  return MobileMoneyOperator.mtn;
}

// Airtel prefixes  
if (prefix == '070' || prefix == '074' || prefix == '075') {
  return MobileMoneyOperator.airtel;
}
```

### PawaPay API Request

**MTN Request Example:**
```json
{
  "depositId": "uuid-v4",
  "amount": "50000.00",
  "currency": "UGX",
  "country": "UGA",
  "correspondent": "MTN_MOMO_UGA",
  "payer": {
    "type": "MSISDN",
    "address": {
      "value": "+256772123456"
    }
  }
}
```

**Airtel Request Example:**
```json
{
  "depositId": "uuid-v4",
  "amount": "50000.00",
  "currency": "UGX",
  "country": "UGA",
  "correspondent": "AIRTEL_OAPI_UGA",
  "payer": {
    "type": "MSISDN",
    "address": {
      "value": "+256702123456"
    }
  }
}
```

---

## ⚠️ Common Issues

### Unknown Operator Error
**Error Message:** `"Could not detect mobile money operator. Please use MTN (077, 078, 076, 079, 031, 039) or Airtel (070, 074, 075) number."`

**Causes:**
- Using a non-supported prefix
- Incorrectly formatted phone number
- Using a different country's number

**Solution:**
- Verify the phone number starts with one of the supported prefixes
- Ensure proper format (0XXXXXXXXX or +256XXXXXXXXX)
- Only use Ugandan mobile money numbers

---

## 📊 Coverage Statistics

### MTN Mobile Money
- **Prefixes:** 6 (077, 078, 031, 039, 076, 079)
- **Market Share:** ~80% of Uganda mobile money users
- **Transaction Limit:** Varies by account type

### Airtel Money
- **Prefixes:** 3 (070, 074, 075)
- **Market Share:** ~20% of Uganda mobile money users  
- **Transaction Limit:** Varies by account type

---

## 🧪 Testing Numbers

For testing in **Sandbox Mode**, use PawaPay's test numbers:

**MTN Test Number:** `0772000001` (Always approves)  
**Airtel Test Number:** `0702000001` (Always approves)

**Production Mode:** Use real Ugandan mobile money numbers

---

## 📚 References

- **PawaPay API Docs:** https://docs.pawapay.io/
- **MTN Uganda:** https://www.mtn.co.ug/momo/
- **Airtel Uganda:** https://www.airtel.co.ug/airtelmoney/

---

**Last Updated:** November 20, 2025  
**App Version:** 1.0.0
