# 🎯 Deployment Checklist

Danh sách kiểm tra toàn bộ quá trình deploy dự án.

---

## ✅ PRE-DEPLOYMENT (Chuẩn Bị)

### Code Quality
- [ ] `flutter analyze` - No issues
- [ ] `flutter build web --release` - Success
- [ ] All tests passing
- [ ] No console.logs sensitive data
- [ ] Git repo is clean

### Configuration
- [ ] `backend/package.json` has `start` script
- [ ] `backend/.env.example` updated
- [ ] `lib/config/api_config.dart` ready for switching
- [ ] CORS configured in backend
- [ ] Database backups enabled

### Documentation
- [ ] README.md updated
- [ ] DEPLOYMENT_GUIDE.md reviewed
- [ ] API documentation up-to-date
- [ ] Environment variables documented

---

## 🚀 DEPLOYMENT STAGE 1: Database Setup

### MongoDB Atlas
- [ ] Create free MongoDB account
- [ ] Create cluster (M0 Free)
- [ ] Create database user
- [ ] Whitelist IP (0.0.0.0/0)
- [ ] Copy connection string
- [ ] Enable automatic backups

**Checkpoint**: `mongodb+srv://admin:pass@cluster.mongodb.net/`

---

## 🚀 DEPLOYMENT STAGE 2: Backend (Railway)

### Railway Account & Project
- [ ] Create Railway account (GitHub OAuth)
- [ ] Create new project on Railway
- [ ] Connect GitHub repo

### Deploy Backend
- [ ] Select root directory: `/backend`
- [ ] Railway detects `package.json`
- [ ] Railway auto-builds and deploys
- [ ] Deployment succeeds ✓

### Configure Environment
- [ ] Set `MONGODB_URI`
- [ ] Set `JWT_SECRET` (random string)
- [ ] Set `NODE_ENV=production`
- [ ] Set `FRONTEND_URL` (from Firebase later)

### Verify Backend
- [ ] Get Railway URL (e.g., `https://xxx.railway.app`)
- [ ] Test health endpoint: `/health` → `{"status":"ok"}`
- [ ] Check logs: `railway logs`
- [ ] API Docs accessible: `/docs`

**Checkpoint**: Backend URL → `https://your-backend.railway.app`

---

## 🚀 DEPLOYMENT STAGE 3: Frontend (Firebase)

### Firebase Account & Project
- [ ] Create Firebase account (or login)
- [ ] Create new Firebase project
- [ ] Enable Hosting

### Firebase CLI Setup
- [ ] Install Firebase CLI: `npm install -g firebase-tools`
- [ ] Login: `firebase login`
- [ ] Initialize: `firebase init hosting`
  - [ ] Public directory: `build/web`
  - [ ] Single-page app: `Y`
  - [ ] Overwrite index.html: `N`

### Build Flutter Web
- [ ] Delete old build: `flutter clean`
- [ ] Build: `flutter build web --release`
- [ ] Verify: `ls build/web/index.html`

### Deploy to Firebase
- [ ] Deploy: `firebase deploy`
- [ ] Note URL: `https://your-project.web.app`
- [ ] Test website loads ✓

**Checkpoint**: Frontend URL → `https://your-project.web.app`

---

## 🔗 STAGE 4: Integration

### Update Configuration
- [ ] Update `lib/config/api_config.dart`:
  - [ ] `productionApiUrl` = Railway URL
  - [ ] `isProduction = true`
- [ ] Rebuild: `flutter build web --release`
- [ ] Redeploy: `firebase deploy`

### Backend CORS Update (if needed)
- [ ] Update `backend/src/server.js` CORS origins
- [ ] Include Firebase URL
- [ ] Commit and Railway auto-deploys

### Test Integration
- [ ] Frontend loads successfully
- [ ] Can login/register (API calls work)
- [ ] Check browser DevTools → Network
- [ ] No CORS errors
- [ ] Token saved in secure storage
- [ ] Navigation works

---

## 📊 STAGE 5: Testing

### Functionality Tests
- [ ] Login/Register works
- [ ] Create transaction works
- [ ] View wallets works
- [ ] View budgets works
- [ ] Search functionality works
- [ ] Profile update works
- [ ] Logout works

### Performance Tests
- [ ] Page load time < 3s
- [ ] API response time < 1s
- [ ] No memory leaks (DevTools)
- [ ] Responsive design works
- [ ] Offline handling (if implemented)

### Security Tests
- [ ] No sensitive data in localStorage
- [ ] HTTPS enforced
- [ ] JWT token protected
- [ ] CORS headers correct
- [ ] SQL injection protected (Mongoose)

---

## 📈 STAGE 6: Monitoring & Logging

### Railway Monitoring
- [ ] Check application logs
- [ ] Monitor CPU usage
- [ ] Check memory usage
- [ ] Database connections

### Firebase Monitoring
- [ ] View hosting analytics
- [ ] Check site traffic
- [ ] Monitor error rates

### Set Up Alerts (Optional)
- [ ] Error notifications
- [ ] Low disk space warnings
- [ ] High CPU/memory alerts

---

## 📝 STAGE 7: Documentation & Handover

### Documentation
- [ ] README with deployment links
- [ ] API documentation updated
- [ ] Environment variables documented
- [ ] Deployment steps verified
- [ ] Troubleshooting guide included

### Final Links
- [ ] Frontend: `https://your-project.web.app`
- [ ] Backend API: `https://your-backend.railway.app`
- [ ] API Docs: `https://your-backend.railway.app/docs`
- [ ] GitHub: `https://github.com/phanducnam14/MoneyPlan`

### Handover Docs
- [ ] Create list of admin accounts
- [ ] Document database backups
- [ ] Create maintenance guide
- [ ] Setup monitoring

---

## 📱 BONUS: Mobile Deployment (Optional)

### Android APK
- [ ] Build: `flutter build apk --release`
- [ ] Sign APK
- [ ] Upload to Google Play Store

### iOS
- [ ] Build: `flutter build ios --release`
- [ ] Sign certificate
- [ ] Upload to App Store

---

## 🎓 Post-Deployment

### Code Review
- [ ] Do final code review
- [ ] Check for any TODOs
- [ ] Verify no hardcoded URLs/secrets

### Team Communication
- [ ] Share deployment links with team
- [ ] Document any issues encountered
- [ ] Update project status

### Usage Tracking
- [ ] Enable analytics (Firebase/Railway)
- [ ] Setup error tracking
- [ ] Monitor user engagement

---

## ✨ Success Criteria

- ✅ Frontend accessible via Firebase URL
- ✅ Backend API working via Railway URL
- ✅ Database connected and syncing
- ✅ Login/Register functionality working
- ✅ All CRUD operations functional
- ✅ No console errors or warnings
- ✅ Performance acceptable (< 3s load time)
- ✅ Mobile responsive design working
- ✅ Documentation complete
- ✅ Team is trained on maintenance

---

## 📞 Support & Troubleshooting

If you encounter issues during deployment:

1. **Check logs**:
   - Railway: `railway logs`
   - Firebase: Dashboard console
   - Browser: DevTools F12

2. **Reference guides**:
   - [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) - Overall process
   - [RAILWAY_SETUP.md](./RAILWAY_SETUP.md) - Backend specific
   - [FIREBASE_SETUP.md](./FIREBASE_SETUP.md) - Frontend specific

3. **Common issues**: See troubleshooting section in main DEPLOYMENT_GUIDE

---

## 🎉 Deployment Complete!

Once all items are checked:
✅ You have a production-ready application
✅ Perfect portfolio piece for interviews
✅ Ready to explain architecture to interviewers
✅ Demonstrates full-stack capabilities

**Good luck with your internship interviews!** 🚀
