# 🔥 QUICK FIX: Firebase Auth Error

## 🎯 The Problem
Your app shows Firebase authentication error because the sandbox domain isn't authorized.

## ✅ The Solution (2 minutes)

### **Step 1: Open Firebase Console**
👉 https://console.firebase.google.com/project/sayekataleapp/authentication/settings

### **Step 2: Add Domain**
1. Scroll to **"Authorized domains"**
2. Click **"+ Add domain"**
3. Type: `sandbox.novita.ai`
4. Click **"Add"**

### **Step 3: Test**
1. Hard refresh: `Ctrl + Shift + R`
2. Try registration

## ✅ Done!

---

## 📸 Visual Guide

```
Firebase Console
├── Authentication
│   ├── Users
│   └── Settings ← Click here
│       └── Authorized domains
│           ├── localhost
│           ├── sayekataleapp.firebaseapp.com
│           └── sandbox.novita.ai ← Add this!
```

---

## 🔗 Quick Links

**Firebase Console:**
https://console.firebase.google.com/

**Your Project:**
https://console.firebase.google.com/project/sayekataleapp

**Authentication Settings (Direct Link):**
https://console.firebase.google.com/project/sayekataleapp/authentication/settings

**Your App:**
https://5060-i25ra390rl3tp6c83ufw7-583b4d74.sandbox.novita.ai

---

## ⚡ Quick Commands

**If you need to rebuild:**
```bash
cd /home/user/flutter_app
flutter clean
flutter pub get
flutter build web --release
cd build/web && python3 -m http.server 5060 --bind 0.0.0.0
```

---

## 🎯 What to Add

**Domain:** `sandbox.novita.ai`

**OR use wildcard:** `*.sandbox.novita.ai`

---

That's it! Just add the domain and your Firebase auth will work! 🚀
