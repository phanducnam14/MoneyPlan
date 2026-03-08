# Railway Deployment Guide

## 📋 Chuẩn Bị

### 1. Tạo Railway Account

Truy cập: https://railway.app

- Click **Sign up with GitHub**
- Authorize Railway
- Xong!

### 2. Tạo MongoDB Atlas Database

Truy cập: https://www.mongodb.com/cloud/atlas

#### Setup MongoDB

1. **Create Account** (nếu chưa có)
2. **Create Organization** (free tier)
3. **Create Project**: Đặt tên `MoneyPlan`
4. **Build Database**: Chọn **M0 (Free)**
5. **Select Provider**: AWS, Region: ap-southeast-1 (Việt Nam)
6. **Create Cluster**: Cứ chọn defaults

#### Cấu hình Security

1. Click **Network Access**
2. Click **Add IP Address**
3. Chọn **Allow Access from Anywhere** (0.0.0.0/0)
4. Click **Database Access**
5. Create database user: `admin` / `strong_password`
6. Copy connection string: `mongodb+srv://admin:password@cluster.mongodb.net/`

---

## 🚀 Deploy Backend to Railway

### Method 1: Dashboard (Recommended)

#### Step 1: Connect GitHub

1. Vào https://railway.app/dashboard
2. Click **+ New Project**
3. Chọn **Deploy from GitHub**
4. Click **Configure GitHub App**
5. Select repo: `MoneyPlan`
6. Authorize

#### Step 2: Deploy Service

1. Click **+ Add Service**
2. Chọn **GitHub Repo**
3. Select `phanducnam14/MoneyPlan`
4. **Service Settings**:
   - Root Directory: `backend`
   - Leave others as default
5. Click **Deploy**

#### Step 3: Add Environment Variables

1. Click vào service (backend)
2. Tab **Variables**
3. Thêm variables:

```env
MONGODB_URI=mongodb+srv://admin:password@cluster.mongodb.net/smart_finance?retryWrites=true&w=majority
JWT_SECRET=super_secret_key_generate_random_string_here_min_32_chars
NODE_ENV=production
PORT=3000
FRONTEND_URL=https://your-firebase-project.web.app
```

#### Step 4: Auto Deploy

Railway sẽ tự deploy khi có push to GitHub!

---

### Method 2: Railway CLI

```bash
# Install Railway CLI
npm install -g @railway/cli

# Login
railway login

# Navigate to backend
cd backend

# Deploy
railway up
```

---

## 📊 Monitoring & Configuration

### Logs

```bash
railway logs
```

Hoặc từ dashboard:
1. Click service
2. Tab **Logs**

### Environment Variables từ Dashboard

1. Click service
2. Tab **Variables**
3. Add/Edit variables

### Deployment History

Dashboard → Deployments tab

---

## 🔗 Get Backend URL

Railway automatically generates:
```
https://[service-name]-[random].railway.app
```

Hoặc cạnh "Connect" sẽ có link.

**Verify it works:**
```bash
curl https://[your-railway-url].railway.app/health
# Should return: {"status":"ok"}
```

---

## 🔄 Auto Deployments

Railway sẽ auto-deploy khi:
- Push to main branch
- Backend files thay đổi

Disable auto-deploy:
1. Click service
2. Settings
3. Disable Auto Deploy

---

## 💾 Database Backups

MongoDB Atlas:
1. Vào Atlas dashboard
2. Cluster → Backup
3. Enable automatic backups

---

## 🆘 Troubleshooting

### Service not starting

Check logs:
```bash
railway logs
```

Common issues:
- ❌ MONGODB_URI wrong format
- ❌ JWT_SECRET not set
- ❌ PORT not using env variable
- ❌ package.json missing `start` script

### Connection refused

```bash
# Test locally first
cd backend
npm install
npm start
```

### CORS errors

Update `backend/src/server.js`:

```javascript
app.use(cors({
  origin: ['https://your-firebase.web.app', 'http://localhost:3000'],
  credentials: true,
}));
```

---

## 📈 Performance Tips

### 1. Database Indexing

Add indexes trên frequently queried fields

### 2. API Caching

Use Redis (available on Railway)

### 3. Monitor Logs

Check for expensive queries

---

## 🔒 Security Checklist

- ✅ JWT_SECRET is strong & random
- ✅ MONGODB_URI has auth
- ✅ CORS configured for frontend only
- ✅ Environment is `production`
- ✅ No secrets in code
- ✅ Database backups enabled
- ✅ IP whitelist if possible

---

## ✨ You're Done!

Backend is now live! 🎉

Next steps:
1. Note down your Railway URL
2. Update `lib/config/api_config.dart` with the URL
3. Build and deploy frontend to Firebase
4. Test the full stack!

**Backend URL**: `https://your-project.railway.app`
**API Docs**: `https://your-project.railway.app/docs`
