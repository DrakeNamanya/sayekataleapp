# 🚀 Quick Test Reference Card

## 🔗 App URL
**https://5060-i25ra390rl3tp6c83ufw7-de59bda9.sandbox.novita.ai**

⚠️ **HARD REFRESH:** Press `Ctrl+Shift+R` (Windows/Linux) or `Cmd+Shift+R` (Mac)

---

## 👥 Test Accounts

### Buyer Account (Sarah)
```
Email: sarah.buyer@test.com
Password: Test123456!
Role: SME/Buyer
Name: Sarah Buyer
Phone: +256700000001
```

### Farmer 1 (John Nama)
```
Email: john.nama@test.com
Password: Test123456!
Role: SHG/Farmer
Name: John Nama
Phone: +256700111111
```

### Farmer 2 (Ngobi Peter)
```
Email: ngobi.peter@test.com
Password: Test123456!
Role: SHG/Farmer
Name: Ngobi Peter
Phone: +256700222222
```

---

## 🎯 Quick Test Flow

### 1️⃣ Create Accounts (5 min)
- Create all 3 accounts above
- Verify each logs in successfully

### 2️⃣ Add Products (5 min)
**John Nama:**
- Tomatoes: 5000 UGX/kg, stock 100
- Cabbage: 3000 UGX/kg, stock 50

**Ngobi Peter:**
- Beans: 8000 UGX/kg, stock 80
- Maize: 6000 UGX/kg, stock 120

### 3️⃣ Place Order (3 min)
**As Sarah:**
- Add Tomatoes (10kg) + Cabbage (5kg) from John Nama
- Add Beans (6kg) from Ngobi Peter
- Checkout → Place Order
- **Expect:** 2 separate orders created

### 4️⃣ Test Real-time (2 min)
**Open 2 browser tabs:**
- Tab 1: John Nama (Orders screen)
- Tab 2: Sarah (Orders screen)

**Verify:** Order appears in John's tab without refresh!

### 5️⃣ Accept Order (1 min)
**As John Nama:**
- Click "Accept Order"
- **Verify:** Sarah sees status change to "CONFIRMED" instantly

### 6️⃣ Reject Order (1 min)
**As Ngobi Peter:**
- Click "Reject" on Beans order
- Reason: "Out of stock"
- **Verify:** Sarah sees rejection reason

### 7️⃣ Complete Order (3 min)
**As John Nama:**
- Mark as Preparing → Ready → In Transit → Delivered
- **Verify:** Sarah sees each status update in real-time
- **Verify:** Revenue card shows 65,000 UGX

---

## ✅ Success Criteria

- [ ] All accounts created
- [ ] Products added by farmers
- [ ] Orders placed successfully
- [ ] Real-time updates working
- [ ] Accept/Reject functional
- [ ] Status progression works
- [ ] Revenue tracking correct
- [ ] Multi-farmer orders split

---

## 🔥 Critical Tests

1. **Real-time Order Notification** - Farmer sees order immediately
2. **Status Updates** - Buyer sees changes without refresh
3. **Revenue Tracking** - Updates after delivery
4. **Multi-farmer Split** - Separate orders created

---

## 🐛 Found Issues?

Document here:
1. _______________
2. _______________
3. _______________

---

**Total Test Time: ~20 minutes**

See `PHASE_4_TESTING_GUIDE.md` for detailed instructions!
