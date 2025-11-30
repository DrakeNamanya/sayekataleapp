# 🌐 Custom Domain Setup Guide - datacollectors.org

## **Current Status**: Web Portals Built ✅ | DNS Configuration Pending

---

## **📋 Overview**

This guide will help you set up **datacollectors.org** to serve your Flutter web app with multiple portal pages.

**Live Preview URL** (sandbox): https://5060-in9hu1x2vblsbdru37ud5-18e660f9.sandbox.novita.ai

**Target URLs** (after setup):
- `https://datacollectors.org/` → Main landing page
- `https://datacollectors.org/sme` → SME (Buyers) portal
- `https://datacollectors.org/shg` → SHG (Farmers) portal
- `https://datacollectors.org/psa` → PSA (Suppliers) portal
- `https://datacollectors.org/admin` → Admin portal

---

## **🚀 Step-by-Step Setup**

### **Step 1: Deploy to Firebase Hosting** 🔥

**Why Firebase Hosting?**
- Free SSL certificate (HTTPS)
- Global CDN for fast loading
- Easy custom domain configuration
- Built-in CI/CD support

**Deployment Steps**:

```bash
# Navigate to your project (on local machine or Google Cloud Shell)
cd /path/to/sayekataleapp

# Login to Firebase (if not already logged in)
firebase login

# Initialize Firebase Hosting (first time only)
firebase init hosting

# Configuration options:
# - What do you want to use as your public directory? → build/web
# - Configure as a single-page app? → Yes
# - Set up automatic builds and deploys with GitHub? → No (optional)

# Build Flutter web app for production
flutter build web --release

# Deploy to Firebase Hosting
firebase deploy --only hosting
```

**Expected Output**:
```
✔  Deploy complete!

Project Console: https://console.firebase.google.com/project/sayekataleapp
Hosting URL: https://sayekataleapp.web.app
```

---

### **Step 2: Configure Firebase Custom Domain** 🌐

**In Firebase Console**:

1. Go to: **https://console.firebase.google.com/project/sayekataleapp/hosting**
2. Click **"Add custom domain"**
3. Enter: **datacollectors.org**
4. Firebase will provide DNS records:
   - **A records** (for root domain)
   - **TXT record** (for verification)

**Example DNS Records Provided**:
```
Type: A
Name: @
Value: 151.101.1.195

Type: A
Name: @
Value: 151.101.65.195

Type: TXT
Name: @
Value: firebase-hosting-verification=xxxxxxxxxxxxxxxx
```

---

### **Step 3: Configure Namecheap DNS** 📡

**Login to Namecheap**:
1. Go to: **https://www.namecheap.com/**
2. Login to your account
3. Navigate to: **Domain List** → **datacollectors.org** → **Manage**

**Configure DNS Settings**:
1. Click **"Advanced DNS"** tab
2. **Delete** any existing A records or CNAME records pointing to other services
3. **Add the records provided by Firebase**:

**Add A Records** (for root domain):
```
Type: A Record
Host: @
Value: 151.101.1.195
TTL: Automatic

Type: A Record
Host: @
Value: 151.101.65.195
TTL: Automatic
```

**Add TXT Record** (for ownership verification):
```
Type: TXT Record
Host: @
Value: firebase-hosting-verification=xxxxxxxxxxxxxxxx
TTL: Automatic
```

**Optional: Add www subdomain**:
```
Type: CNAME Record
Host: www
Value: datacollectors.org.
TTL: Automatic
```

**Save all changes** ✅

---

### **Step 4: Wait for DNS Propagation** ⏳

**DNS propagation** typically takes:
- **Namecheap**: 30 minutes - 48 hours
- **Global DNS**: Up to 72 hours (usually 24 hours)

**Check DNS propagation**:
- **Tool**: https://dnschecker.org/
- **Enter**: datacollectors.org
- **Check for**: Firebase A records (151.101.x.x)

**Firebase will automatically**:
- Verify domain ownership (TXT record)
- Issue SSL certificate (via Let's Encrypt)
- Enable HTTPS

---

### **Step 5: Verify Setup** ✅

**After DNS propagation completes**:

1. **Check Firebase Console**:
   - Status should show: **"Connected"** (green checkmark)
   - SSL certificate: **"Active"**

2. **Test URLs**:
   ```
   https://datacollectors.org/ → Main landing page
   https://datacollectors.org/sme → SME portal
   https://datacollectors.org/shg → SHG portal
   https://datacollectors.org/psa → PSA portal
   https://datacollectors.org/admin → Admin portal
   ```

3. **Verify HTTPS**:
   - Check for padlock icon in browser
   - Certificate issuer: Let's Encrypt
   - Valid for: datacollectors.org

---

## **🎨 Web Portal Structure**

Your Flutter web app includes these portal pages:

### **1. Main Landing Page** (`/`)
**File**: `lib/screens/web/web_landing_page.dart`

**Features**:
- Hero section with CTA
- Role selection cards (SME, SHG, PSA, Admin)
- Features showcase
- Statistics section
- Footer with contact info

**Screenshots**: (Coming soon)

---

### **2. SME Portal** (`/sme`)
**File**: `lib/screens/web/sme_portal_page.dart`

**Target Users**: Buyers & Small-Medium Enterprises

**Features**:
- Product browsing capabilities
- Order management system
- Real-time delivery tracking
- Distance-based sorting
- Digital receipts

**Call-to-Action**: Login / Register → OnboardingScreen

---

### **3. SHG Portal** (`/shg`)
**File**: `lib/screens/web/shg_portal_page.dart`

**Target Users**: Self-Help Groups & Farmers

**Features**:
- Product listing management
- Inventory control
- Order fulfillment
- Delivery coordination
- Payment tracking

**Call-to-Action**: Login / Register → OnboardingScreen

---

### **4. PSA Portal** (`/psa`)
**File**: `lib/screens/web/psa_portal_page.dart`

**Target Users**: Private Sector Agents & Suppliers

**Features**:
- Bulk inventory management
- Large-scale order processing
- Fleet management
- Business analytics
- Performance optimization

**Call-to-Action**: Login / Register → OnboardingScreen

---

### **5. Admin Portal** (`/admin`)
**File**: `lib/screens/admin/admin_web_portal.dart` (existing)

**Target Users**: System Administrators

**Features**:
- User management
- Analytics dashboard
- System configuration
- Reports generation

**Access**: Requires admin authentication

---

## **🔧 Technical Implementation**

### **Firebase Hosting Configuration**

**File**: `firebase.json`

```json
{
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ],
    "headers": [
      {
        "source": "**/*.@(jpg|jpeg|gif|png|svg|webp|js|css|eot|otf|ttf|ttc|woff|woff2|font.css)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "max-age=604800"
          }
        ]
      }
    ]
  }
}
```

---

### **Flutter Web Routing**

**File**: `lib/main.dart`

```dart
MaterialApp(
  home: const WebLandingPage(), // Default route
  routes: {
    '/': (context) => const WebLandingPage(),
    '/sme': (context) => const SMEPortalPage(),
    '/shg': (context) => const SHGPortalPage(),
    '/psa': (context) => const PSAPortalPage(),
    '/admin': (context) => const AdminWebPortal(),
    '/onboarding': (context) => const OnboardingScreen(),
    // ... other routes
  },
)
```

---

## **📊 Performance Optimization**

### **Web App Performance**:
- **Build size**: Optimized with tree-shaking
- **Load time**: < 3 seconds (with CDN)
- **Lighthouse score**: 90+ (target)

### **CDN Benefits**:
- **Global distribution**: Firebase CDN
- **SSL/TLS**: Automatic certificate
- **HTTP/2**: Enabled by default
- **Compression**: Gzip + Brotli

---

## **🔒 Security Considerations**

### **HTTPS Enforcement**:
```dart
// Firebase Hosting automatically redirects HTTP → HTTPS
// No additional configuration needed
```

### **Security Headers** (add to firebase.json if needed):
```json
{
  "headers": [
    {
      "source": "/**",
      "headers": [
        {
          "key": "X-Content-Type-Options",
          "value": "nosniff"
        },
        {
          "key": "X-Frame-Options",
          "value": "SAMEORIGIN"
        }
      ]
    }
  ]
}
```

---

## **🧪 Testing Checklist**

### **Before DNS Changes**:
- [x] Flutter web app builds successfully
- [x] All portal pages accessible in sandbox preview
- [x] Navigation between pages works correctly
- [x] OnboardingScreen integration functional

### **After Deployment**:
- [ ] Firebase deployment successful
- [ ] Hosting URL works (sayekataleapp.web.app)
- [ ] All routes accessible via hosting URL

### **After DNS Setup**:
- [ ] Custom domain DNS configured
- [ ] DNS propagation completed
- [ ] HTTPS certificate issued
- [ ] All portal URLs work (datacollectors.org/*)
- [ ] SEO meta tags present
- [ ] Mobile responsiveness verified

---

## **📞 Support Resources**

### **Firebase Console**:
- **Project**: sayekataleapp
- **Hosting**: https://console.firebase.google.com/project/sayekataleapp/hosting
- **Documentation**: https://firebase.google.com/docs/hosting

### **Namecheap Support**:
- **Domain Dashboard**: https://ap.namecheap.com/domains/list/
- **DNS Help**: https://www.namecheap.com/support/knowledgebase/article.aspx/767/10/how-to-change-dns-for-a-domain/
- **Support**: https://www.namecheap.com/support/

### **DNS Propagation Checker**:
- **DNSChecker**: https://dnschecker.org/
- **WhatsmyDNS**: https://whatsmydns.net/
- **Google DNS**: https://dns.google/

---

## **🎉 Next Steps**

1. **Deploy to Firebase Hosting** ✅ (Complete in Google Cloud Shell)
2. **Configure Namecheap DNS** ⏳ (Add Firebase DNS records)
3. **Wait for propagation** ⏳ (24-48 hours)
4. **Verify HTTPS** ✅ (Automatic after propagation)
5. **Test all portal URLs** ✅
6. **Update SEO meta tags** (optional enhancement)
7. **Set up Firebase Analytics** (optional tracking)

---

## **📝 Current Implementation Status**

✅ **Completed**:
- Web portal pages created (landing, SME, SHG, PSA)
- Flutter routing configured
- Responsive design implemented
- OnboardingScreen integration
- Firebase Cloud Functions deployed
- Delivery tracking with photos
- GPS-based distance calculation

⏳ **Pending**:
- Firebase Hosting deployment
- Namecheap DNS configuration
- Custom domain verification
- SSL certificate activation

---

**Deployment Date**: 2024  
**Domain**: datacollectors.org  
**Project**: SAYE KATALE  
**Platform**: Flutter Web + Firebase Hosting  

**Ready for production deployment!** 🚀

