# Backend Data Isolation - Testing & Verification Guide

## Quick Verification Checklist

### ✅ Code Changes Verification

- [x] **Middleware** (`auth.js`): ObjectId conversion in middleware
  - `req.user.userId` is now `new mongoose.Types.ObjectId(decoded.id)`
  - Both string `id` and ObjectId `userId` stored for flexibility

- [x] **Models** (`Expense.js`, `Income.js`): Indexes created
  - userId field has index: `index: true`
  - Compound index: `{ userId: 1, date: -1 }`

- [x] **Controllers** (all three updated):
  - `expenseController.js`: Proper ObjectId conversion in queries
  - `incomeController.js`: Proper ObjectId conversion in queries  
  - `authController.js`: Password filtered from responses
  - `adminController.js`: Enhanced with per-user stats

- [x] **Routes**: Profile endpoints added
  - `GET /auth/profile` - Get current user's profile
  - `POST /auth/profile` - Update current user's profile
  - `GET /admin/users/:id/stats` - Admin view user stats

## Manual Testing Steps

### Test 1: Complete Data Isolation Flow

```bash
# Using curl or Postman

# STEP 1: Register User A
POST http://localhost:3000/auth/register
{
  "name": "Alice",
  "email": "alice@test.com",
  "password": "pass123",
  "dateOfBirth": "1990-01-01",
  "gender": "female"
}
RESPONSE: Get TOKEN_A and user data

# STEP 2: Get Profile (verify no password)
GET http://localhost:3000/auth/profile
Headers: Authorization: Bearer TOKEN_A
EXPECTED: User profile WITHOUT password field

# STEP 3: Create expense for User A
POST http://localhost:3000/expenses
Headers: Authorization: Bearer TOKEN_A
{
  "amount": 50,
  "category": "Food",
  "note": "Lunch",
  "date": "2024-03-07T12:00:00Z"
}
RESPONSE: Expense created with userId matching User A

# STEP 4: List expenses for User A
GET http://localhost:3000/expenses
Headers: Authorization: Bearer TOKEN_A
EXPECTED: Should return 1 expense

# STEP 5: Register User B
POST http://localhost:3000/auth/register
{
  "name": "Bob",
  "email": "bob@test.com",
  "password": "pass456",
  "dateOfBirth": "1992-05-15",
  "gender": "male"
}
RESPONSE: Get TOKEN_B and user data

# STEP 6: List expenses for User B - CRITICAL TEST
GET http://localhost:3000/expenses
Headers: Authorization: Bearer TOKEN_B
EXPECTED OUTPUT: 
{
  "data": [],
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 0,
    "pages": 0
  }
}
⭐ MUST BE EMPTY! If not empty, data isolation is broken

# STEP 7: Create 3 expenses for User B
POST http://localhost:3000/expenses
Headers: Authorization: Bearer TOKEN_B
{
  "amount": 75,
  "category": "Transport",
  "note": "Taxi",
  "date": "2024-03-06T15:00:00Z"
}
(repeat 2 more times with different amounts)

# STEP 8: Verify User A still sees only their data
GET http://localhost:3000/expenses
Headers: Authorization: Bearer TOKEN_A
EXPECTED: Should return exactly 1 expense (from Step 3)
NOT 4 expenses!

# STEP 9: Verify User B sees only their data
GET http://localhost:3000/expenses
Headers: Authorization: Bearer TOKEN_B
EXPECTED: Should return exactly 3 expenses (from Step 7)
```

### Test 2: Authorization & Ownership Verification

```bash
# From Test 1, we have:
# - USER_A_EXPENSE_ID from Step 3
# - USER_B has TOKEN_B

# ATTEMPT: User B tries to update User A's expense
PUT http://localhost:3000/expenses/{USER_A_EXPENSE_ID}
Headers: Authorization: Bearer TOKEN_B
{
  "amount": 999
}
EXPECTED: 404 with message "Expense not found or access denied"
⭐ MUST NOT update! Must reject access

# ATTEMPT: User B tries to delete User A's expense
DELETE http://localhost:3000/expenses/{USER_A_EXPENSE_ID}
Headers: Authorization: Bearer TOKEN_B
EXPECTED: 404 with message "Expense not found or access denied"
⭐ MUST NOT delete! Must reject access

# SUCCESS CASE: User A updates their own expense
PUT http://localhost:3000/expenses/{USER_A_EXPENSE_ID}
Headers: Authorization: Bearer TOKEN_A
{
  "amount": 60,
  "note": "Updated lunch expense"
}
EXPECTED: 200 OK with updated expense
```

### Test 3: Income Data Isolation

```bash
# Same as expenses, but with incomes endpoint

# Create income for User A
POST http://localhost:3000/incomes
Headers: Authorization: Bearer TOKEN_A
{
  "amount": 3000,
  "source": "Salary",
  "note": "Monthly salary",
  "date": "2024-03-01T00:00:00Z"
}

# List incomes for User B (should be empty)
GET http://localhost:3000/incomes
Headers: Authorization: Bearer TOKEN_B
EXPECTED: Empty array

# List incomes for User A
GET http://localhost:3000/incomes
Headers: Authorization: Bearer TOKEN_A
EXPECTED: Should contain the income created above

# Pagination test
GET http://localhost:3000/incomes?page=1&limit=5
Headers: Authorization: Bearer TOKEN_A
EXPECTED: Should have pagination metadata
```

### Test 4: Profile Management

```bash
# Get initial profile
GET http://localhost:3000/auth/profile
Headers: Authorization: Bearer TOKEN_A
RESPONSE: Store current profile

# Update profile
POST http://localhost:3000/auth/profile
Headers: Authorization: Bearer TOKEN_A
{
  "name": "Alice Smith",
  "monthlyBudget": 5000,
  "avatar": "https://example.com/alice.jpg"
}
EXPECTED: 200 OK with updated profile

# Verify changes
GET http://localhost:3000/auth/profile
Headers: Authorization: Bearer TOKEN_A
EXPECTED: Should reflect updates (name, budget, avatar)
         Password should NOT be in response
```

### Test 5: Admin Statistics

```bash
# Register admin user (or use existing admin)
# Login to get ADMIN_TOKEN

# Get global system stats
GET http://localhost:3000/admin/stats
Headers: Authorization: Bearer ADMIN_TOKEN
EXPECTED:
{
  "userCount": 2,
  "totalExpenses": 225,      // User A: 50-60 (updated) + User B: 75+75+75
  "totalExpenseCount": 4,
  "totalIncomes": 3000,
  "totalIncomeCount": 1,
  "timestamp": "2024-03-07T..."
}

# Get stats for specific user
GET http://localhost:3000/admin/users/{USER_A_ID}/stats
Headers: Authorization: Bearer ADMIN_TOKEN
EXPECTED:
{
  "user": {
    "_id": "...",
    "name": "Alice Smith",
    "email": "alice@test.com",
    "role": "user"
  },
  "expenses": {
    "total": 60,              // Updated value
    "count": 1,
    "average": 60
  },
  "incomes": {
    "total": 3000,
    "count": 1,
    "average": 3000
  }
}
```

### Test 6: Pagination Consistency

```bash
# Create 15 expenses for User A
for i in {1..15}
POST http://localhost:3000/expenses
Headers: Authorization: Bearer TOKEN_A
{
  "amount": 10 + i,
  "category": "Test",
  "date": "2024-03-07T12:0$i:00Z"
}

# Get page 1 (default limit 10)
GET http://localhost:3000/expenses?page=1&limit=10
Headers: Authorization: Bearer TOKEN_A
EXPECTED: 
{
  "data": [...],           // 10 items
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 15,
    "pages": 2
  }
}

# Get page 2
GET http://localhost:3000/expenses?page=2&limit=10
Headers: Authorization: Bearer TOKEN_A
EXPECTED:
{
  "data": [...],           // 5 items (remaining)
  "pagination": {
    "page": 2,
    "limit": 10,
    "total": 15,
    "pages": 2
  }
}

# Test with incomes too
GET http://localhost:3000/incomes?page=1&limit=5
Headers: Authorization: Bearer TOKEN_A
EXPECTED: Pagination metadata present
```

## Expected Behavior After Fixes

### ✅ Data is Properly Isolated
- User A cannot see User B's data
- User B cannot see User A's data
- New users start with empty financial data

### ✅ Authorization Works
- Users can only update/delete their own records
- Attempting to access others' records returns 404
- Admin can view system-wide and per-user statistics

### ✅ Response Format Improved
- Pagination added to all list endpoints
- Password never returned in any response
- Consistent error messages and HTTP status codes
- Proper metadata in responses

### ✅ Performance Optimized
- Indexes on userId field
- Compound indexes on (userId, date)
- Pagination prevents loading huge datasets

## Troubleshooting

### Issue: Getting "Invalid token" errors
**Solution**: Ensure JWT_SECRET environment variable is set consistently

### Issue: ObjectId conversion errors
**Solution**: Check that MongoDB connection is established before requests

### Issue: Pagination returning wrong data
**Solution**: Verify limit is between 1-100, page is positive integer

### Issue: 404 when accessing own records
**Solution**: Verify token was properly extracted (Bearer prefix in Authorization header)

### Issue: Auth token expired
**Solution**: Tokens expire in 7 days. Need to login again for new token

## Database Verification Commands

### Check Indexes Were Created
```javascript
// In MongoDB shell or MongoDB Compass
use smart_finance
db.expenses.getIndexes()
db.incomes.getIndexes()

// Should show:
// - { userId: 1 }
// - { userId: 1, date: -1 }
```

### Verify Data Isolation
```javascript
// Count expenses per user
db.expenses.aggregate([
  { $group: { _id: "$userId", count: { $sum: 1 } } }
])

// Should show each user's expenses separated
// No expenses should be missing userId
```

### Check for Data Integrity
```javascript
// Find any expenses/incomes without userId
db.expenses.find({ userId: { $exists: false } })
db.incomes.find({ userId: { $exists: false } })

// Should return: []
```

## Success Criteria

All tests PASS when:
- ✅ User A and User B see completely different data
- ✅ User B gets empty arrays when trying to access User A's IDs
- ✅ Passwords never appear in API responses
- ✅ Pagination works consistently
- ✅ Admin statistics are accurate and per-user
- ✅ New users start with zero expenses/incomes
- ✅ All error responses have proper HTTP status codes
- ✅ Indexes are properly created in database

## Regression Testing

Run these tests regularly after any backend changes:

1. **Data Isolation Test** (Most Critical)
2. **Authorization Test** (Security Critical)
3. **Pagination Test** (Consistency)
4. **Profile Test** (Data Accuracy)

If all these pass, data isolation is secure.
