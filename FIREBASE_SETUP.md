# Firebase Hosting Setup Guide

## 📋 Chuẩn Bị

### 1. Cài đặt Firebase CLI

```bash
npm install -g firebase-tools
```

### 2. Kiểm tra version

```bash
firebase --version
```

---

## 🚀 Quick Setup

### Step 1: Login Firebase

```bash
firebase login
```

Điều hướng sẽ mở browser để bạn login bằng Google account.

### Step 2: Initialize Firebase Project

```bash
# Từ thư mục root của MoneyPlan
firebase init hosting

# Khi được hỏi, chọn:
# - Select a Firebase project: Chọn project của bạn
# - What do you want to use as public directory?: build/web
# - Configure as single-page app?: Y
# - Set up automatic builds and deploys?: N (currently)
# - Overwrite index.html?: N
```

### Step 3: Build Flutter Web

```bash
flutter clean
flutter build web --release
```

### Step 4: Deploy

```bash
firebase deploy
```

Bạn sẽ nhận được URL: `https://[project-id].web.app`

---

## 📁 Firebase Config Files

Sau khi init, bạn sẽ có:

```
.firebaserc          # Project config
firebase.json        # Hosting config
.gitignore          # Updated to ignore firebase files
```

### Modify firebase.json

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
    ]
  }
}
```

---

## ✅ Verification

### Check Files

```bash
firebase projects:list
```

### Test Local Hosting (Optional)

```bash
firebase emulators:start --only hosting
```

Truy cập: `http://localhost:5000`

---

## 🔄 Redeploy sau khi update

```bash
# Update code
# ...

# Rebuild
flutter build web --release

# Redeploy
firebase deploy
```

---

## 🆘 Troubleshooting

### Build folder không tìm thấy

```bash
flutter build web --release
ls build/web/  # hoặc dir build\web
```

### Firebase login không work

```bash
firebase logout
firebase login
```

### Version mismatch

```bash
npm install -g firebase-tools@latest
firebase --version
```

### CORS errors

Cập nhật `api_config.dart`:

```dart
static const bool isProduction = true;
// hoặc set production URL
static const String productionApiUrl = 'https://your-api.railway.app';
```

---

## 📊 Monitoring Deployment

```bash
# View deployment logs
firebase hosting:channel:open default

# List deployments
firebase hosting:releases:list

# Rollback if needed
firebase hosting:releases:rollback
```

---

## 🔒 Security Headers (Advanced)

Edit `firebase.json`:

```json
{
  "hosting": {
    "headers": [
      {
        "source": "**",
        "headers": [
          {
            "key": "X-Content-Type-Options",
            "value": "nosniff"
          },
          {
            "key": "X-Frame-Options",
            "value": "DENY"
          }
        ]
      }
    ]
  }
}
```

---

## ✨ Done!

Dự án của bạn giờ đã live trên Firebase Hosting! 🎉

Sau khi deploy cả frontend và backend:
- Frontend: `https://your-project.web.app`
- Backend: `https://your-project.railway.app`
