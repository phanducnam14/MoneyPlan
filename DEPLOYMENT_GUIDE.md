# 🚀 Deployment Guide - MoneyPlan

Hướng dẫn chi tiết để deploy dự án Full Stack với **Railway (Backend)** và **Firebase Hosting (Frontend)**.

---

## 📋 Yêu Cầu Trước Deploy

- ✅ GitHub account (đã có)
- ✅ Railway account (signup miễn phí)
- ✅ Firebase account (signup miễn phí)
- ✅ Flutter SDK (đã cài)
- ✅ Node.js (để local testing)

---

## 🔹 BƯỚC 1: Chuẩn Bị Backend

### 1.1 Cập Nhật package.json

Thêm script `start` cho Railway:

```json
{
  "scripts": {
    "dev": "node src/server.js",
    "start": "node src/server.js"
  }
}
```

### 1.2 Kiểm Tra Backend Environment Variables

File: `backend/.env`

```env
# Database
MONGODB_URI=your_mongodb_uri_here

# JWT
JWT_SECRET=your_jwt_secret_here

# Environment
NODE_ENV=production

# Server Port
PORT=3000

# Frontend URL (cập nhật sau khi deploy)
FRONTEND_URL=https://your-firebaseapp.web.app
```

### 1.3 Thêm `.gitignore.backend`

```
node_modules/
.env
.env.local
```

---

## 🔹 BƯỚC 2: Deploy Backend lên Railway

### 2.1 Tạo Account Railway
1. Truy cập: https://railway.app
2. Signup bằng GitHub
3. Authorize Railway

### 2.2 Deploy Backend

**Cách 1: Từ Railway Dashboard (Dễ nhất)**

1. Vào Railway Dashboard
2. Click **+ New Project**
3. Chọn **Deploy from GitHub**
4. Chọn repo `MoneyPlan`
5. Chọn root directory: `/backend`
6. Railway sẽ tự detect `package.json`

**Cách 2: Từ CLI**

```bash
# Cài Railway CLI
npm install -g @railway/cli

# Login
railway login

# Deploy
cd backend
railway up
```

### 2.3 Cấu Hình Environment Variables Trên Railway

1. Vào project Railway
2. Click vào service (backend)
3. Chọn tab **Variables**
4. Thêm các biến:

```env
MONGODB_URI=[MongoDB connection string]
JWT_SECRET=[Random secret string]
NODE_ENV=production
PORT=3000
FRONTEND_URL=https://[your-project].web.app
```

### 2.4 Kiểm Tra Backend URL

- Railway sẽ tạo URL như: `https://[project-name]-production.railway.app`
- Test health check: `https://[project-name]-production.railway.app/health`

---

## 🔹 BƯỚC 3: Build Flutter Web

### 3.1 Update API Config

File: `lib/config/api_config.dart`

```dart
class ApiConfig {
  // Production
  static const String baseUrl = 'https://[your-railway-url].railway.app';
  // hoặc local
  // static const String baseUrl = 'http://localhost:3000';
}
```

### 3.2 Build Flutter Web

```bash
# Cài Flutter web dependencies
flutter pub get

# Build web
flutter build web --release
```

Output: `build/web/`

### 3.3 Kiểm Tra Assets & Dependencies

```bash
# Verify build (optional)
flutter analyze
```

---

## 🔹 BƯỚC 4: Deploy Frontend lên Firebase Hosting

### 4.1 Cài Firebase CLI

```bash
npm install -g firebase-tools
```

### 4.2 Login Firebase

```bash
firebase login
```

### 4.3 Tạo Firebase Project

1. Truy cập: https://console.firebase.google.com
2. Create New Project
3. Tên: `MoneyPlan` (hoặc tên khác)
4. Enable Hosting

### 4.4 Initialize Firebase

```bash
# Trong thư mục project root
firebase init hosting

# Firebase CLI sẽ hỏi:
# - Select project: Chọn project vừa tạo
# - What do you want to use as your public directory? 
#   → Answer: build/web
# - Configure as a single-page app?
#   → Answer: Y (Yes)
```

### 4.5 Deploy to Firebase

```bash
# Deploy
firebase deploy

# Hoặc only hosting
firebase deploy --only hosting
```

Firebase sẽ output URL: `https://[project-id].web.app`

---

## 🔹 BƯỚC 5: Cấu Hình CORS & API URLs

### 5.1 Backend CORS Settings (Optional)

File: `backend/src/server.js`

```javascript
app.use(cors({
  origin: ['https://[your-firebaseapp].web.app', 'http://localhost:3000'],
  credentials: true,
}));
```

### 5.2 Frontend API Config Update

Cập nhật `lib/config/api_config.dart`:

```dart
class ApiConfig {
  static const String baseUrl = 'https://[your-railway-url].railway.app';
}
```

Rebuild & redeploy frontend nếu cần thay đổi.

---

## 📊 Testing Deployment

### Test Backend API

```bash
# Health check
curl https://[your-railway-url].railway.app/health

# Test login (example)
curl -X POST https://[your-railway-url].railway.app/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@gmail.com","password":"password123","name":"Test"}'
```

### Test Frontend

- Mở browser: `https://[project-id].web.app`
- Test login functionality
- Verify API calls working

### Logs

**Railway Logs:**
```bash
railway logs
```

**Firebase Logs:**
```bash
firebase hosting:channel:open [channel-name]
```

---

## 🔒 Production Checklist

- ✅ Backend PORT từ environment variable
- ✅ CORS configured cho frontend domain
- ✅ MongoDB connection string (production)
- ✅ JWT Secret set (random, strong)
- ✅ API_CONFIG pointing to production backend
- ✅ No console.logs sensitive data
- ✅ Error handling implemented
- ✅ HTTPS enforced
- ✅ Database backups enabled

---

## 🔗 URLs Sau Khi Deploy

| Service | URL |
|---------|-----|
| **Backend API** | `https://[project].railway.app` |
| **Docs/Swagger** | `https://[project].railway.app/docs` |
| **Frontend Web** | `https://[project-id].web.app` |
| **GitHub Repo** | `https://github.com/phanducnam14/MoneyPlan` |

---

## 🆘 Troubleshooting

### Backend không chạy
- Kiểm tra `package.json` có script `start`
- Kiểm tra environment variables trên Railway
- Check Railway logs: `railway logs`

### Frontend không kết nối API
- Verify API_CONFIG baseUrl
- Check CORS settings trên backend
- Open browser DevTools → Network tab
- Verify token được save trên secure storage

### Database connection error
- Verify MONGODB_URI format
- Kiểm tra MongoDB IP whitelist (allow all: 0.0.0.0/0)
- Test local connection trước

### Firebase deployment error
- Verify `build/web/` tồn tại
- Login lại: `firebase logout && firebase login`
- Rebuild: `flutter clean && flutter build web --release`

---

## 📝 Tài Liệu Tham Khảo

- Railway Docs: https://docs.railway.app
- Firebase Hosting: https://firebase.google.com/docs/hosting
- Flutter Web: https://flutter.dev/web
- Express.js: https://expressjs.com

---

## ✨ Tổng Kết Setup

```
MoneyPlan (Full Stack)
├── Backend (Node.js + Express + MongoDB)
│   └── Deployed on Railway
├── Frontend (Flutter Web)
│   └── Deployed on Firebase Hosting
└── Database (MongoDB)
    └── Cloud (Atlas / Compass)
```

**Estimated Deploy Time:** 15-30 phút 🚀

Sau khi deploy, bạn sẽ có:
- ✅ Live production API
- ✅ Live production web app  
- ✅ Professional portfolio project
- ✅ Ready for internship interviews! 💼
