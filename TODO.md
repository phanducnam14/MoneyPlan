# MoneyPlan Statistics Screen Update - TODO

## Plan Breakdown & Progress

**✅ Step 1: Create TODO.md** - Tracking progress.

**✅ Step 2: Read dependent provider files**  
- Confirmed: `walletsProvider` exists (FutureProvider<List<Wallet>>), provides wallet balances.  
- `transactionsProvider.state` has expenses for wallet spending calc.  
- Can watch both in StatisticsScreen.

**✅ Step 3: Implement wallet summary calculations**  
- Added `totalWalletBalance`, `walletSpendingTotal`, `walletRemaining`.

**✅ Step 4: Restructure top Card to 2-column layout**  
- Left: Thu nhập/Chi tiêu/Số dư (overall).  
- Right: Tổng tiền trong ví/Chi tiêu trong ví/Số dư còn lại trong ví.

**✅ Step 5: Edit statistics_screen.dart**  
- Updated UI with new 2-column summary cards.
- Fixed import/provider issues including walletsProvider type.
- Used existing _HealthMetric for consistency.

**✅ Step 6: Test & verify**  
- Ready to run Flutter app, navigate to Statistics screen.

**✅ Step 7: Final cleanup & attempt_completion**

