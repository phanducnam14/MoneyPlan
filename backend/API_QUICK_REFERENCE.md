# MoneyPlan API - Quick Reference Guide

## 🏁 Quick Start

### 1. Register User
```http
POST /auth/register
Content-Type: application/json

{
  "name": "Alice",
  "email": "alice@test.com",
  "password": "securepass123",
  "dateOfBirth": "1995-01-15",
  "gender": "female"
}

Response: 201 Created
{
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "user": { ... }
}
```

### 2. Login
```http
POST /auth/login
Content-Type: application/json

{
  "email": "alice@test.com",
  "password": "securepass123"
}

Response: 200 OK
{
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "user": { ... }
}
```

### 3. Get Default Wallet
```http
GET /wallets
Authorization: Bearer <token>

Response: 200 OK
{
  "data": [
    {
      "_id": "wallet-id",
      "name": "My Wallet",
      "actualBalance": 0,
      ...
    }
  ]
}
```

---

## 💰 Transaction Operations

### Add Income
```http
POST /transactions/income
Authorization: Bearer <token>
Content-Type: application/json

{
  "amount": 5000000,
  "category": "Lương",
  "source": "Monthly Salary",
  "note": "March payment",
  "walletId": "wallet-id",
  "date": "2026-03-01T00:00:00Z"
}

Response: 201 Created
{
  "_id": "transaction-id",
  "type": "income",
  "amount": 5000000,
  "status": "completed",
  ...
}
```

### Add Expense
```http
POST /transactions/expense
Authorization: Bearer <token>
Content-Type: application/json

{
  "amount": 50000,
  "category": "Ăn uống",
  "note": "Coffee",
  "walletId": "wallet-id",
  "date": "2026-03-05T00:00:00Z"
}

Response: 201 Created
{
  "_id": "transaction-id",
  "type": "expense",
  "amount": 50000,
  "status": "completed",
  ...
}
```

### Transfer Between Wallets
```http
POST /transactions/transfer
Authorization: Bearer <token>
Content-Type: application/json

{
  "fromWalletId": "wallet-1-id",
  "toWalletId": "wallet-2-id",
  "amount": 500000,
  "note": "Move to bank",
  "date": "2026-03-10T00:00:00Z"
}

Response: 201 Created
{
  "transactions": [
    { "type": "expense", "walletId": "wallet-1-id", ... },
    { "type": "income", "walletId": "wallet-2-id", ... }
  ],
  "message": "Transfer created successfully"
}
```

---

## 📊 View Transactions

### Get All User Transactions
```http
GET /transactions
Authorization: Bearer <token>

Response: 200 OK
{
  "data": [ { transaction }, ... ],
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 25,
    "pages": 3
  }
}
```

### Get Wallet Transactions
```http
GET /transactions/wallet/wallet-id
Authorization: Bearer <token>

Response: 200 OK
{
  "data": [ { transaction }, ... ],
  "pagination": { ... }
}
```

### Filter Transactions
```http
GET /transactions?type=expense&category=Ăn uống
Authorization: Bearer <token>

Query Parameters:
- type: 'income', 'expense', 'transfer'
- category: 'Ăn uống', 'Lương', etc.
- walletId: wallet-id
- startDate: 2026-01-01
- endDate: 2026-12-31
- page: 1
- limit: 10
```

### Get Statistics
```http
GET /transactions/stats
Authorization: Bearer <token>

Response: 200 OK
{
  "byType": [
    { "_id": "income", "total": 5000000, "count": 1 },
    { "_id": "expense", "total": 400000, "count": 4 }
  ],
  "byCategory": [ ... ],
  "summary": {
    "income": 5000000,
    "expense": 400000,
    "transfer": 500000
  }
}
```

---

## 💼 Wallet Operations

### Get All Wallets
```http
GET /wallets
Authorization: Bearer <token>

Response: 200 OK
{
  "data": [
    {
      "_id": "wallet-id",
      "name": "My Wallet",
      "type": "cash",
      "actualBalance": 4600000,
      "isDefault": true,
      ...
    }
  ]
}
```

### Create New Wallet
```http
POST /wallets
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "Savings",
  "type": "savings",
  "balance": 1000000,
  "icon": "savings",
  "color": "#4CAF50"
}

Response: 201 Created
{
  "_id": "new-wallet-id",
  "name": "Savings",
  "actualBalance": 1000000,
  ...
}
```

### Get Wallet Details
```http
GET /wallets/wallet-id
Authorization: Bearer <token>

Response: 200 OK
{
  "_id": "wallet-id",
  "name": "My Wallet",
  "actualBalance": 4600000,
  "displayBalance": 4600000,
  "recentTransactions": [ ... ]
}
```

### Update Wallet
```http
PUT /wallets/wallet-id
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "My Savings",
  "icon": "trending_up",
  "color": "#FF9800"
}

Response: 200 OK
{
  "_id": "wallet-id",
  "name": "My Savings",
  ...
}
```

### Delete Wallet
```http
DELETE /wallets/wallet-id
Authorization: Bearer <token>

Response: 204 No Content
(Empty response)
```

---

## 🔄 Update & Delete Transactions

### Update Transaction
```http
PUT /transactions/transaction-id
Authorization: Bearer <token>
Content-Type: application/json

{
  "amount": 100000,
  "category": "Ăn uống",
  "note": "Updated note",
  "date": "2026-03-05T00:00:00Z"
}

Response: 200 OK
{
  "_id": "transaction-id",
  "amount": 100000,
  ...
}
```

### Delete Transaction
```http
DELETE /transactions/transaction-id
Authorization: Bearer <token>

Response: 204 No Content
(Empty response)

Note: Balance automatically adjusted
```

---

## 👤 User Profile

### Get Profile
```http
GET /auth/profile
Authorization: Bearer <token>

Response: 200 OK
{
  "_id": "user-id",
  "name": "Alice",
  "email": "alice@test.com",
  "monthlyBudget": 10000000,
  ...
}
```

### Update Profile
```http
PUT /auth/profile
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "Alice Updated",
  "monthlyBudget": 15000000,
  "avatar": "avatar-url"
}

Response: 200 OK
{
  "_id": "user-id",
  "name": "Alice Updated",
  ...
}
```

### Get User Statistics
```http
GET /auth/stats
Authorization: Bearer <token>

Response: 200 OK
{
  "expenses": {
    "total": 400000,
    "count": 4,
    "average": 100000
  },
  "incomes": {
    "total": 5000000,
    "count": 1,
    "average": 5000000
  },
  "summary": {
    "totalIncomes": 5000000,
    "totalExpenses": 400000,
    "balance": 4600000,
    "lastUpdated": "2026-03-13T00:00:00Z"
  }
}
```

---

## ⚠️ Error Responses

### 400 Bad Request
```json
{
  "message": "Amount, category, and date are required"
}
```

### 401 Unauthorized
```json
{
  "message": "Invalid token"
}
```

### 403 Forbidden
```json
{
  "message": "Forbidden"
}
```

### 404 Not Found
```json
{
  "message": "Wallet not found or access denied"
}
```

### 500 Server Error
```json
{
  "message": "Error creating transaction",
  "error": "details"
}
```

---

## 📋 Request Headers

All authenticated requests require:
```
Authorization: Bearer <token>
Content-Type: application/json
```

---

## 🔑 Common Field Values

### Transaction Type
```
income    - Money coming in
expense   - Money going out
transfer  - Money between wallets
```

### Source Type
```
externalIncome  - From outside (salary, freelance)
wallet          - From another wallet (transfer)
external        - General external source
```

### Wallet Type
```
cash         - Physical cash
bank         - Bank account
savings      - Savings account
investment   - Investment account
other        - Other type
```

### Categories (Examples)
```
Expense:
- Ăn uống      (Food & Drink)
- Nhà ở        (Housing)
- Di chuyển    (Transportation)
- Giải trí     (Entertainment)
- Học tập      (Education)
- Sức khỏe     (Health)
- Mua sắm      (Shopping)

Income:
- Lương        (Salary)
- Freelance    (Freelance work)
- Đầu tư       (Investment)
- Quà tặng     (Gifts)
```

---

## 💡 Example Workflow

### Step 1: User Registration
```bash
POST /auth/register
→ Creates user
→ Auto-creates "My Wallet"
→ Auto-creates categories
```

### Step 2: Add Income
```bash
POST /transactions/income
→ Creates income transaction
→ Wallet balance updated
```

### Step 3: Add Expenses
```bash
POST /transactions/expense (multiple times)
→ Each creates expense transaction
→ Wallet balance decreases
```

### Step 4: Create Another Wallet
```bash
POST /wallets
→ Creates new wallet
→ Can add transactions to it
```

### Step 5: Transfer Money
```bash
POST /transactions/transfer
→ Creates linked transactions
→ Both wallets updated
```

### Step 6: View History
```bash
GET /transactions
→ All transactions visible
→ Can filter by type, category, wallet

GET /wallets
→ All wallets with current balances
→ Can drill down to wallet details
```

---

## 🧮 Balance Formula

```
Wallet Balance = Initial Balance + Total Income - Total Expenses
```

Example:
```
Initial:     1,000,000
+ Income:    5,000,000
- Expense:     400,000
= Balance:   5,600,000
```

---

## 📱 Frontend Integration

### TypeScript Interface
```typescript
interface Transaction {
  _id: string;
  userId: string;
  walletId: string;
  type: 'income' | 'expense' | 'transfer';
  amount: number;
  category: string;
  note?: string;
  date: Date;
  sourceType: 'externalIncome' | 'wallet' | 'external';
  status: 'pending' | 'completed' | 'cancelled';
  createdAt: Date;
  updatedAt: Date;
}

interface Wallet {
  _id: string;
  userId: string;
  name: string;
  balance: number;
  actualBalance: number;
  type: 'cash' | 'bank' | 'savings' | 'investment' | 'other';
  isDefault: boolean;
  icon: string;
  color: string;
  createdAt: Date;
  updatedAt: Date;
}
```

---

## 🚀 Deployment Checklist

- [ ] Backend running on 3000 (or configured port)
- [ ] MongoDB connected and accessible
- [ ] JWT_SECRET set in .env
- [ ] Database backup done
- [ ] Test scenarios run successfully
- [ ] CORS configured for frontend
- [ ] HTTPS enabled in production
- [ ] Error monitoring setup
- [ ] Database indexes created
- [ ] Rate limiting configured

---

## 🆘 Troubleshooting

### Issue: "Wallet not found"
**Solution**: Check wallet exists and belongs to user
```bash
GET /wallets  # Verify wallet exists
```

### Issue: "Invalid amount"
**Solution**: Amount must be > 0
```json
{
  "amount": 50000  // ✓ Correct
}
```

### Issue: "Balance seems wrong"
**Solution**: Balance calculated as: initial + income - expense
```bash
GET /wallets/:id  # View actualBalance
```

### Issue: "Cannot transfer to same wallet"
**Solution**: Use different wallet IDs
```json
{
  "fromWalletId": "wallet-1",
  "toWalletId": "wallet-2"  // Must be different
}
```

---

## 📞 API Documentation

**Full API Docs**: Available at `/docs` endpoint
- **Testing**: See COMPREHENSIVE_TESTING_GUIDE.md
- **Architecture**: See IMPLEMENTATION_COMPLETE.md
- **Security**: See SECURITY_AUDIT_REPORT.md

---

**Version**: 1.0.0
**Last Updated**: 2026-03-13
**Status**: Production Ready ✅
