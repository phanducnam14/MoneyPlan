# 📋 Postman API Testing Guide - Personal Finance App

Complete guide for testing all APIs of the Flutter Personal Finance Application with MongoDB backend.

---

## 🚀 Quick Setup

### Base URL
```
http://localhost:5000/api
```

### Environment Variables (Postman)
Create a new Postman Environment with these variables:

```json
{
  "BASE_URL": "http://localhost:5000/api",
  "TOKEN_USER_A": "your_token_here",
  "TOKEN_USER_B": "your_token_here",
  "USER_A_ID": "user_a_id",
  "USER_B_ID": "user_b_id",
  "EMAIL_A": "usera@example.com",
  "EMAIL_B": "userb@example.com"
}
```

### Headers Template (All Authenticated Requests)
```json
{
  "Content-Type": "application/json",
  "Authorization": "Bearer {{TOKEN_USER_A}}"
}
```

---

## 📱 Authentication Endpoints

### 1. Register New User
**POST** `{{BASE_URL}}/auth/register`

**Headers:**
```json
{
  "Content-Type": "application/json"
}
```

**Body (Raw JSON):**
```json
{
  "name": "Nguyen Van A",
  "email": "usera@example.com",
  "password": "password123",
  "dateOfBirth": "1990-01-15",
  "gender": "male"
}
```

**Expected Response (201):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "_id": "507f1f77bcf86cd799439011",
    "id": "507f1f77bcf86cd799439011",
    "name": "Nguyen Van A",
    "email": "usera@example.com",
    "role": "user",
    "monthlyBudget": 0,
    "dateOfBirth": "1990-01-15",
    "gender": "male"
  }
}
```

**✅ Test Steps:**
1. Register User A with email `usera@example.com`
2. Copy the token and save to `TOKEN_USER_A` environment variable
3. Register User B with email `userb@example.com` 
4. Copy the token and save to `TOKEN_USER_B` environment variable
5. Verify both users get different tokens

---

### 2. Login
**POST** `{{BASE_URL}}/auth/login`

**Body:**
```json
{
  "email": "usera@example.com",
  "password": "password123"
}
```

**Expected Response (200):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "_id": "507f1f77bcf86cd799439011",
    "name": "Nguyen Van A",
    "email": "usera@example.com",
    "role": "user"
  }
}
```

**✅ Test Steps:**
1. Login with User A credentials
2. Verify token is returned
3. Login with wrong password → Should return 401
4. Login with non-existent email → Should return 401

---

### 3. Get User Profile
**GET** `{{BASE_URL}}/auth/profile`

**Headers:**
```json
{
  "Authorization": "Bearer {{TOKEN_USER_A}}"
}
```

**Expected Response (200):**
```json
{
  "_id": "507f1f77bcf86cd799439011",
  "name": "Nguyen Van A",
  "email": "usera@example.com",
  "role": "user",
  "monthlyBudget": 0,
  "dateOfBirth": "1990-01-15",
  "gender": "male",
  "createdAt": "2026-03-07T10:00:00.000Z"
}
```

**✅ Test Steps:**
1. Get profile with valid token → Should succeed
2. Get profile without token → Should return 401
3. Get profile with invalid token → Should return 401

---

### 4. Update User Profile
**POST** `{{BASE_URL}}/auth/profile`

**Headers:**
```json
{
  "Authorization": "Bearer {{TOKEN_USER_A}}",
  "Content-Type": "application/json"
}
```

**Body:**
```json
{
  "name": "Nguyen Van A Updated",
  "monthlyBudget": 10000000,
  "avatar": "https://example.com/avatar.jpg"
}
```

**Expected Response (200):**
```json
{
  "_id": "507f1f77bcf86cd799439011",
  "name": "Nguyen Van A Updated",
  "monthlyBudget": 10000000,
  "avatar": "https://example.com/avatar.jpg",
  "email": "usera@example.com",
  "role": "user"
}
```

---

### 5. Get User Statistics
**GET** `{{BASE_URL}}/auth/stats`

**Headers:**
```json
{
  "Authorization": "Bearer {{TOKEN_USER_A}}"
}
```

**Expected Response (200) - New User:**
```json
{
  "expenses": {
    "total": 0,
    "count": 0,
    "average": 0
  },
  "incomes": {
    "total": 0,
    "count": 0,
    "average": 0
  },
  "summary": {
    "totalIncomes": 0,
    "totalExpenses": 0,
    "balance": 0,
    "lastUpdated": "2026-03-07T10:15:00.000Z"
  }
}
```

**✅ Test Steps:**
1. Get stats for new user → Should be all zeros
2. Add some expenses/incomes (see below)
3. Get stats again → Should show updated totals

---

### 6. Reset User Financial Data
**POST** `{{BASE_URL}}/auth/reset-data`

**Headers:**
```json
{
  "Authorization": "Bearer {{TOKEN_USER_A}}"
}
```

**Expected Response (200):**
```json
{
  "message": "Financial data reset successfully",
  "data": {
    "expensesDeleted": 5,
    "incomesDeleted": 3,
    "timestamp": "2026-03-07T10:20:00.000Z"
  }
}
```

**✅ Test Steps:**
1. Add expenses/incomes to User A
2. Call reset endpoint with User A token → Should delete all data
3. Can only User A reset User A's data (test with User B token → Should fail)
4. Check stats after reset → Should be zeros again

---

## 💰 Expense Management Endpoints

### 7. Get All Expenses (Paginated)
**GET** `{{BASE_URL}}/expenses?page=1&limit=10`

**Headers:**
```json
{
  "Authorization": "Bearer {{TOKEN_USER_A}}"
}
```

**Expected Response (200):**
```json
{
  "data": [
    {
      "_id": "507f1f77bcf86cd799439012",
      "userId": "507f1f77bcf86cd799439011",
      "amount": 250000,
      "category": "Ăn uống",
      "date": "2026-03-05T10:00:00.000Z",
      "note": "Ăn cơm trưa",
      "createdAt": "2026-03-07T10:00:00.000Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 1,
    "pages": 1
  }
}
```

**✅ Test Steps:**
1. Get expenses for User A (should see only User A's expenses)
2. Get expenses for User B (should see only User B's expenses, not User A's)
3. Test pagination with `limit=2` and `page=2`
4. Verify data isolation between users

---

### 8. Create Expense
**POST** `{{BASE_URL}}/expenses`

**Headers:**
```json
{
  "Authorization": "Bearer {{TOKEN_USER_A}}",
  "Content-Type": "application/json"
}
```

**Body:**
```json
{
  "amount": 250000,
  "category": "Ăn uống",
  "date": "2026-03-07T12:00:00.000Z",
  "note": "Ăn cơm trưa khoa học"
}
```

**Expected Response (201):**
```json
{
  "_id": "507f1f77bcf86cd799439012",
  "userId": "507f1f77bcf86cd799439011",
  "amount": 250000,
  "category": "Ăn uống",
  "date": "2026-03-07T12:00:00.000Z",
  "note": "Ăn cơm trưa khoa học",
  "createdAt": "2026-03-07T10:00:00.000Z"
}
```

**✅ Test Steps:**
1. Create 5 expenses for User A with different categories:
   - Ăn uống: 250,000
   - Nhà ở: 3,000,000
   - Di chuyển: 100,000
   - Giải trí: 500,000
   - Học tập: 200,000
2. Create expenses for User B
3. Verify User A only sees their expenses
4. Verify User B only sees their expenses

**Categories to test:**
- Ăn uống
- Nhà ở
- Di chuyển
- Giải trí
- Học tập
- Khác

---

### 9. Get Single Expense
**GET** `{{BASE_URL}}/expenses/{{EXPENSE_ID}}`

**Headers:**
```json
{
  "Authorization": "Bearer {{TOKEN_USER_A}}"
}
```

**✅ Test Steps:**
1. Get an expense belonging to User A → Should succeed
2. Get an expense belonging to User B using User A token → Should return 404 (access denied)

---

### 10. Update Expense
**PUT** `{{BASE_URL}}/expenses/{{EXPENSE_ID}}`

**Headers:**
```json
{
  "Authorization": "Bearer {{TOKEN_USER_A}}",
  "Content-Type": "application/json"
}
```

**Body:**
```json
{
  "amount": 300000,
  "category": "Ăn uống",
  "note": "Ăn cơm trưa (cập nhật)"
}
```

**Expected Response (200):**
```json
{
  "_id": "507f1f77bcf86cd799439012",
  "userId": "507f1f77bcf86cd799439011",
  "amount": 300000,
  "category": "Ăn uống",
  "note": "Ăn cơm trưa (cập nhật)"
}
```

**✅ Test Steps:**
1. Update User A's expense → Should succeed
2. Try updating User B's expense with User A token → Should return 404

---

### 11. Delete Expense
**DELETE** `{{BASE_URL}}/expenses/{{EXPENSE_ID}}`

**Headers:**
```json
{
  "Authorization": "Bearer {{TOKEN_USER_A}}"
}
```

**Expected Response (200):**
```json
{
  "message": "Expense deleted successfully"
}
```

**✅ Test Steps:**
1. Delete User A's expense → Should succeed
2. Try deleting User B's expense with User A token → Should return 404
3. Try deleting already-deleted expense → Should return 404

---

## 📈 Income Management Endpoints

### 12. Get All Incomes (Paginated)
**GET** `{{BASE_URL}}/incomes?page=1&limit=10`

**Headers:**
```json
{
  "Authorization": "Bearer {{TOKEN_USER_A}}"
}
```

**Expected Response (200):**
```json
{
  "data": [
    {
      "_id": "507f1f77bcf86cd799439013",
      "userId": "507f1f77bcf86cd799439011",
      "amount": 5000000,
      "source": "Lương",
      "date": "2026-03-01T10:00:00.000Z",
      "note": "Lương tháng 3",
      "createdAt": "2026-03-07T10:00:00.000Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 1,
    "pages": 1
  }
}
```

---

### 13. Create Income
**POST** `{{BASE_URL}}/incomes`

**Headers:**
```json
{
  "Authorization": "Bearer {{TOKEN_USER_A}}",
  "Content-Type": "application/json"
}
```

**Body:**
```json
{
  "amount": 5000000,
  "source": "Lương",
  "date": "2026-03-01T10:00:00.000Z",
  "note": "Lương tháng 3"
}
```

**✅ Test Steps:**
1. Create 3 incomes for User A:
   - Lương: 5,000,000
   - Freelance: 1,500,000
   - Đầu tư: 500,000
2. Create incomes for User B
3. Verify data isolation

**Income sources to test:**
- Lương
- Freelance
- Đầu tư
- Khác

---

### 14. Get Single Income
**GET** `{{BASE_URL}}/incomes/{{INCOME_ID}}`

**Headers:**
```json
{
  "Authorization": "Bearer {{TOKEN_USER_A}}"
}
```

---

### 15. Update Income
**PUT** `{{BASE_URL}}/incomes/{{INCOME_ID}}`

**Headers:**
```json
{
  "Authorization": "Bearer {{TOKEN_USER_A}}",
  "Content-Type": "application/json"
}
```

**Body:**
```json
{
  "amount": 5500000,
  "source": "Lương",
  "note": "Lương tháng 3 (cập nhật)"
}
```

---

### 16. Delete Income
**DELETE** `{{BASE_URL}}/incomes/{{INCOME_ID}}`

**Headers:**
```json
{
  "Authorization": "Bearer {{TOKEN_USER_A}}"
}
```

---

## 🔐 Data Isolation Testing

### Critical Test Scenario: User A Cannot Access User B's Data

**Setup:**
```
1. Create User A and User B (both registered)
2. Create 5 expenses for User A
3. Create 5 expenses for User B
```

**Tests to run:**

#### Test 1: User A Gets Own Expenses
```
Request: GET /expenses
Headers: Authorization: Bearer {{TOKEN_USER_A}}
Expected: Only User A's 5 expenses
```

#### Test 2: User A Cannot Get User B's Expenses
```
Request: GET /expenses/{{USER_B_EXPENSE_ID}}
Headers: Authorization: Bearer {{TOKEN_USER_A}}
Expected: 404 Not Found (or Access Denied)
```

#### Test 3: User A Cannot Update User B's Expense
```
Request: PUT /expenses/{{USER_B_EXPENSE_ID}}
Headers: Authorization: Bearer {{TOKEN_USER_A}}
Body: { "amount": 999999 }
Expected: 404 Not Found (or Unauthorized)
```

#### Test 4: User A Cannot Delete User B's Expense
```
Request: DELETE /expenses/{{USER_B_EXPENSE_ID}}
Headers: Authorization: Bearer {{TOKEN_USER_A}}
Expected: 404 Not Found (or Unauthorized)
```

#### Test 5: Same Tests for Incomes
```
Repeat Tests 1-4 with /incomes endpoints
```

**✅ All should pass - confirming data isolation works!**

---

## 🔄 Reset Feature Testing

### Test Reset Functionality

#### Test 1: Check Stats Before Reset
```
Request: GET /auth/stats
Headers: Authorization: Bearer {{TOKEN_USER_A}}
Expected: Non-zero totals (from previously added data)
```

#### Test 2: Reset User Data
```
Request: POST /auth/reset-data
Headers: Authorization: Bearer {{TOKEN_USER_A}}
Expected: 200 OK with deletion counts
{
  "message": "Financial data reset successfully",
  "data": {
    "expensesDeleted": 5,
    "incomesDeleted": 3
  }
}
```

#### Test 3: Check Stats After Reset
```
Request: GET /auth/stats
Headers: Authorization: Bearer {{TOKEN_USER_A}}
Expected: All zeros
{
  "expenses": { "total": 0, "count": 0, "average": 0 },
  "incomes": { "total": 0, "count": 0, "average": 0 }
}
```

#### Test 4: User B's Data Not Affected
```
Request: GET /incomes
Headers: Authorization: Bearer {{TOKEN_USER_B}}
Expected: User B's original incomes still there
```

---

## 🚨 Error Handling Tests

### Test 400 - Bad Request
```
Request: POST /expenses
Body: { "amount": 100 }  // Missing category, date
Expected: 400 with "Amount, category, and date are required"
```

### Test 401 - Unauthorized
```
Request: GET /expenses
Headers: (no Authorization header)
Expected: 401 Unauthorized
```

### Test 404 - Not Found
```
Request: GET /expenses/999999999999999999999999
Headers: Authorization: Bearer {{TOKEN_USER_A}}
Expected: 404 Not Found
```

### Test 409 - Conflict (Email Already Exists)
```
Request: POST /auth/register
Body: { 
  "name": "User A",
  "email": "usera@example.com",  // Already registered
  "password": "123456"
}
Expected: 400 "Email already exists"
```

---

## 📊 Admin Endpoints (Optional)

### Get All Users (Admin Only)
**GET** `{{BASE_URL}}/admin/users`

**Headers:**
```json
{
  "Authorization": "Bearer {{ADMIN_TOKEN}}"
}
```

---

### Get System Statistics (Admin Only)
**GET** `{{BASE_URL}}/admin/stats`

**Expected Response:**
```json
{
  "userCount": 2,
  "totalExpenses": 8000000,
  "totalExpenseCount": 10,
  "totalIncomes": 12000000,
  "totalIncomeCount": 5
}
```

---

## 🧪 Complete Test Workflow (Step by Step)

### Phase 1: Authentication Setup (10 minutes)
```
1. ✓ Register User A
2. ✓ Register User B
3. ✓ Save tokens to environment
4. ✓ Login with both users
5. ✓ Get and update profiles
```

### Phase 2: Create Financial Data (15 minutes)
```
6. ✓ Create 5 expenses for User A
7. ✓ Create 3 incomes for User A
8. ✓ Create 5 expenses for User B
9. ✓ Create 3 incomes for User B
10. ✓ Verify stats for both users
```

### Phase 3: Data Isolation Testing (10 minutes)
```
11. ✓ User A gets own expenses (should see 5)
12. ✓ User A tries to get User B's expense (should fail)
13. ✓ User A tries to update User B's expense (should fail)
14. ✓ User A tries to delete User B's expense (should fail)
15. ✓ Repeat with incomes
```

### Phase 4: CRUD Operations (10 minutes)
```
16. ✓ Update one of User A's expenses
17. ✓ Delete one of User A's incomes
18. ✓ Verify stats updated correctly
```

### Phase 5: Reset Feature (5 minutes)
```
19. ✓ Check User A stats (should be non-zero)
20. ✓ Reset User A's data
21. ✓ Check User A stats (should be zero)
22. ✓ Verify User B's data not affected
```

### Phase 6: Error Handling (5 minutes)
```
23. ✓ Test 400 errors (missing fields)
24. ✓ Test 401 errors (no token)
25. ✓ Test 404 errors (not found)
26. ✓ Test 409 errors (duplicate email)
```

**Total Time: ~55 minutes**

---

## 💡 Postman Collection Tips

### Import as Collection
Save this entire guide as Postman collection JSON:
```json
{
  "info": {
    "name": "Personal Finance API",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    // Add all requests here
  ]
}
```

### Pre-request Scripts
Use this to automatically set timestamps:
```javascript
pm.environment.set("timestamp", new Date().toISOString());
```

### Tests (Assertions)
Example test to verify response:
```javascript
pm.test("Status is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Response has token", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData).to.have.property('token');
});
```

---

## 🎯 Success Criteria

All tests pass when:
- ✅ Users can register and login
- ✅ Users can create/read/update/delete their own data
- ✅ Users **cannot** access other users' data
- ✅ Stats are calculated correctly
- ✅ Reset feature clears all user data
- ✅ Error responses are appropriate
- ✅ Authentication is enforced on all protected routes

---

## 🚀 Running the Backend

```bash
# Navigate to backend
cd backend

# Install dependencies
npm install

# Start server
npm start

# Expected output:
# Server running on port 5000
# MongoDB connected...
```

**Server will be available at:** `http://localhost:5000`

---

## 📝 Notes

- All timestamps should be in ISO 8601 format
- All currency amounts are in Vietnamese Dong (VND)
- Password must be at least 6 characters
- Tokens expire in 7 days
- Delete operations are permanent and cannot be undone
- Reset feature is safe and only affects the current user

---

## ❓ Troubleshooting

### 401 Unauthorized
- Check token is valid and not expired
- Verify Authorization header format: `Bearer <token>`

### 404 Not Found
- Verify endpoint URL is correct
- Verify resource ID exists and belongs to current user

### 500 Internal Server Error
- Check backend server is running
- Check MongoDB is connected
- Review server logs for details

---

**Happy Testing! 🎉**
