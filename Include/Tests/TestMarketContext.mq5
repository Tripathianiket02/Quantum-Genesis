#property script_show_inputs

#include "../Core/MarketContext.mqh"

//+------------------------------------------------------------------+
//| Project Quantum — Phase 1.4 Market Context / Snapshot Checks      |
//+------------------------------------------------------------------+

void AssertEqualBool(const bool actual,
                     const bool expected,
                     const string test_name,
                     int &tests_run,
                     int &tests_failed)
{
   tests_run++;

   if(actual != expected)
   {
      tests_failed++;
      Print("FAIL: ", test_name, " expected=", expected, " actual=", actual);
      return;
   }

   Print("PASS: ", test_name);
}

void AssertEqualLong(const long actual,
                     const long expected,
                     const string test_name,
                     int &tests_run,
                     int &tests_failed)
{
   tests_run++;

   if(actual != expected)
   {
      tests_failed++;
      Print("FAIL: ", test_name, " expected=", expected, " actual=", actual);
      return;
   }

   Print("PASS: ", test_name);
}

void AssertEqualString(const string actual,
                       const string expected,
                       const string test_name,
                       int &tests_run,
                       int &tests_failed)
{
   tests_run++;

   if(actual != expected)
   {
      tests_failed++;
      Print("FAIL: ", test_name, " expected=", expected, " actual=", actual);
      return;
   }

   Print("PASS: ", test_name);
}

void AssertEqualDouble(const double actual,
                       const double expected,
                       const string test_name,
                       int &tests_run,
                       int &tests_failed)
{
   tests_run++;

   if(MathAbs(actual - expected) > 0.0000001)
   {
      tests_failed++;
      Print("FAIL: ", test_name, " expected=", expected, " actual=", actual);
      return;
   }

   Print("PASS: ", test_name);
}

void InitializeIdentity(CQuantumRuntimeIdentity &identity, const string symbol)
{
   SQuantumResult result;
   identity.Initialize("Q01", "MarketContextTest", symbol, result);
}

MqlTick MakeTick(const double bid, const double ask, const datetime tick_time)
{
   MqlTick tick;
   tick.time = tick_time;
   tick.bid = bid;
   tick.ask = ask;
   tick.last = 0.0;
   tick.volume = 0;
   tick.time_msc = 0;
   tick.flags = 0;
   tick.volume_real = 0.0;
   return tick;
}

void TestInitialState(int &tests_run, int &tests_failed)
{
   CQuantumMarketContext context;

   AssertEqualBool(context.IsInitialized(), false, "new context is not initialized", tests_run, tests_failed);
   AssertEqualLong((long)context.CycleId(), 0, "new context cycle id is zero", tests_run, tests_failed);
   AssertEqualString(context.Symbol(), "", "new context symbol is empty", tests_run, tests_failed);
   AssertEqualLong((long)context.Timeframe(), (long)PERIOD_CURRENT, "new context timeframe is PERIOD_CURRENT", tests_run, tests_failed);
   AssertEqualDouble(context.AccountBalance(), 0.0, "new context account balance is zero", tests_run, tests_failed);
   AssertEqualDouble(context.AccountEquity(), 0.0, "new context account equity is zero", tests_run, tests_failed);
   AssertEqualDouble(context.Tick().bid, 0.0, "new context tick bid is zero", tests_run, tests_failed);
   AssertEqualDouble(context.Tick().ask, 0.0, "new context tick ask is zero", tests_run, tests_failed);
}

void TestInvalidRuntimeIdentityRejected(int &tests_run, int &tests_failed)
{
   CQuantumRuntimeIdentity uninitialized_identity;
   CQuantumMarketContext context;
   SQuantumResult result;
   MqlTick tick = MakeTick(1.10500, 1.10520, D'2026.01.05 08:00:00');

   AssertEqualBool(context.Initialize(uninitialized_identity, PERIOD_M15, 1, tick, 10000.0, 10000.0, result),
                   false, "uninitialized RuntimeIdentity rejected", tests_run, tests_failed);
   AssertEqualLong((long)result.Status, (long)QUANTUM_STATUS_ERROR, "uninitialized identity status error", tests_run, tests_failed);
   AssertEqualLong((long)result.ErrorCode, (long)QUANTUM_ERROR_NOT_INITIALIZED, "uninitialized identity error code", tests_run, tests_failed);
   AssertEqualBool(context.IsInitialized(), false, "context remains uninitialized after rejected identity", tests_run, tests_failed);
}

void TestInvalidTimeframeRejected(int &tests_run, int &tests_failed)
{
   CQuantumRuntimeIdentity identity;
   CQuantumMarketContext context;
   SQuantumResult result;
   InitializeIdentity(identity, "EURUSD");
   MqlTick tick = MakeTick(1.10500, 1.10520, D'2026.01.05 08:00:00');

   AssertEqualBool(context.Initialize(identity, PERIOD_CURRENT, 1, tick, 10000.0, 10000.0, result),
                   false, "PERIOD_CURRENT timeframe rejected", tests_run, tests_failed);
   AssertEqualLong((long)result.Status, (long)QUANTUM_STATUS_ERROR, "invalid timeframe status error", tests_run, tests_failed);
   AssertEqualLong((long)result.ErrorCode, (long)QUANTUM_ERROR_INVALID_ARGUMENT, "invalid timeframe error code", tests_run, tests_failed);
   AssertEqualBool(context.IsInitialized(), false, "context remains uninitialized after rejected timeframe", tests_run, tests_failed);
}

void TestInvalidCycleIdRejected(int &tests_run, int &tests_failed)
{
   CQuantumRuntimeIdentity identity;
   CQuantumMarketContext context;
   SQuantumResult result;
   InitializeIdentity(identity, "EURUSD");
   MqlTick tick = MakeTick(1.10500, 1.10520, D'2026.01.05 08:00:00');

   AssertEqualBool(context.Initialize(identity, PERIOD_M15, 0, tick, 10000.0, 10000.0, result),
                   false, "zero cycle id rejected", tests_run, tests_failed);
   AssertEqualLong((long)result.Status, (long)QUANTUM_STATUS_ERROR, "invalid cycle id status error", tests_run, tests_failed);
   AssertEqualLong((long)result.ErrorCode, (long)QUANTUM_ERROR_INVALID_ARGUMENT, "invalid cycle id error code", tests_run, tests_failed);
   AssertEqualBool(context.IsInitialized(), false, "context remains uninitialized after rejected cycle id", tests_run, tests_failed);
}

void TestInvalidTickRejected(int &tests_run, int &tests_failed)
{
   CQuantumRuntimeIdentity identity;
   SQuantumResult result;
   InitializeIdentity(identity, "EURUSD");

   CQuantumMarketContext zero_tick_context;
   MqlTick zero_tick = MakeTick(0.0, 0.0, D'2026.01.05 08:00:00');
   AssertEqualBool(zero_tick_context.Initialize(identity, PERIOD_M15, 1, zero_tick, 10000.0, 10000.0, result),
                   false, "zeroed bid/ask tick rejected", tests_run, tests_failed);
   AssertEqualLong((long)result.ErrorCode, (long)QUANTUM_ERROR_VALIDATION_FAILED, "zeroed tick error code", tests_run, tests_failed);

   result.Reset();
   CQuantumMarketContext crossed_tick_context;
   MqlTick crossed_tick = MakeTick(1.10520, 1.10500, D'2026.01.05 08:00:00');
   AssertEqualBool(crossed_tick_context.Initialize(identity, PERIOD_M15, 1, crossed_tick, 10000.0, 10000.0, result),
                   false, "crossed bid/ask tick rejected", tests_run, tests_failed);
   AssertEqualLong((long)result.ErrorCode, (long)QUANTUM_ERROR_VALIDATION_FAILED, "crossed tick error code", tests_run, tests_failed);

   result.Reset();
   CQuantumMarketContext zero_time_context;
   MqlTick zero_time_tick = MakeTick(1.10500, 1.10520, 0);
   AssertEqualBool(zero_time_context.Initialize(identity, PERIOD_M15, 1, zero_time_tick, 10000.0, 10000.0, result),
                   false, "zero timestamp tick rejected", tests_run, tests_failed);
   AssertEqualLong((long)result.ErrorCode, (long)QUANTUM_ERROR_VALIDATION_FAILED, "zero timestamp tick error code", tests_run, tests_failed);

   AssertEqualBool(zero_tick_context.IsInitialized(), false, "rejected tick leaves context uninitialized", tests_run, tests_failed);
}

void TestValidConstruction(int &tests_run, int &tests_failed)
{
   CQuantumRuntimeIdentity identity;
   CQuantumMarketContext context;
   SQuantumResult result;
   InitializeIdentity(identity, "EURUSD");
   MqlTick tick = MakeTick(1.10534, 1.10551, D'2026.01.05 08:30:00');

   AssertEqualBool(context.Initialize(identity, PERIOD_M15, 42, tick, 10250.75, 10180.40, result),
                   true, "valid MarketContext construction succeeds", tests_run, tests_failed);
   AssertEqualBool(result.IsOk(), true, "valid construction result ok", tests_run, tests_failed);
   AssertEqualLong((long)result.Component, (long)QUANTUM_COMPONENT_PLATFORM, "valid construction result component", tests_run, tests_failed);
   AssertEqualBool(context.IsInitialized(), true, "constructed context reports initialized", tests_run, tests_failed);
   AssertEqualString(context.Symbol(), "EURUSD", "constructed context symbol correct", tests_run, tests_failed);
   AssertEqualLong((long)context.Timeframe(), (long)PERIOD_M15, "constructed context timeframe correct", tests_run, tests_failed);
   AssertEqualLong((long)context.CycleId(), 42, "constructed context cycle id correct", tests_run, tests_failed);
   AssertEqualDouble(context.Tick().bid, 1.10534, "constructed context tick bid correct", tests_run, tests_failed);
   AssertEqualDouble(context.Tick().ask, 1.10551, "constructed context tick ask correct", tests_run, tests_failed);
   AssertEqualLong((long)context.Tick().time, (long)D'2026.01.05 08:30:00', "constructed context tick time correct", tests_run, tests_failed);
   AssertEqualDouble(context.AccountBalance(), 10250.75, "constructed context account balance correct", tests_run, tests_failed);
   AssertEqualDouble(context.AccountEquity(), 10180.40, "constructed context account equity correct", tests_run, tests_failed);
}

void TestImmutabilityAfterPublish(int &tests_run, int &tests_failed)
{
   CQuantumRuntimeIdentity identity;
   CQuantumRuntimeIdentity other_identity;
   CQuantumMarketContext context;
   SQuantumResult result;
   InitializeIdentity(identity, "EURUSD");
   InitializeIdentity(other_identity, "GBPUSD");
   MqlTick original_tick = MakeTick(1.10534, 1.10551, D'2026.01.05 08:30:00');
   MqlTick other_tick = MakeTick(1.27100, 1.27130, D'2026.01.05 09:00:00');

   context.Initialize(identity, PERIOD_M15, 42, original_tick, 10250.75, 10180.40, result);

   result.Reset();
   AssertEqualBool(context.Initialize(other_identity, PERIOD_H1, 99, other_tick, 5000.0, 4800.0, result),
                   false, "re-initializing a published context is rejected", tests_run, tests_failed);
   AssertEqualLong((long)result.Status, (long)QUANTUM_STATUS_BLOCKED, "re-initialization status blocked", tests_run, tests_failed);
   AssertEqualLong((long)result.ErrorCode, (long)QUANTUM_ERROR_INVALID_STATE, "re-initialization error code", tests_run, tests_failed);

   AssertEqualString(context.Symbol(), "EURUSD", "symbol unchanged after rejected re-initialization", tests_run, tests_failed);
   AssertEqualLong((long)context.Timeframe(), (long)PERIOD_M15, "timeframe unchanged after rejected re-initialization", tests_run, tests_failed);
   AssertEqualLong((long)context.CycleId(), 42, "cycle id unchanged after rejected re-initialization", tests_run, tests_failed);
   AssertEqualDouble(context.Tick().bid, 1.10534, "tick bid unchanged after rejected re-initialization", tests_run, tests_failed);
   AssertEqualDouble(context.AccountBalance(), 10250.75, "account balance unchanged after rejected re-initialization", tests_run, tests_failed);
}

void TestSnapshotIsolation(int &tests_run, int &tests_failed)
{
   CQuantumRuntimeIdentity identity_a;
   CQuantumRuntimeIdentity identity_b;
   CQuantumMarketContext context_a;
   CQuantumMarketContext context_b;
   SQuantumResult result;
   InitializeIdentity(identity_a, "EURUSD");
   InitializeIdentity(identity_b, "GBPUSD");
   MqlTick tick_a = MakeTick(1.10534, 1.10551, D'2026.01.05 08:30:00');
   MqlTick tick_b = MakeTick(1.27100, 1.27130, D'2026.01.05 09:00:00');

   context_a.Initialize(identity_a, PERIOD_M15, 1, tick_a, 10250.75, 10180.40, result);
   result.Reset();
   context_b.Initialize(identity_b, PERIOD_H1, 2, tick_b, 5000.0, 4800.0, result);

   AssertEqualString(context_a.Symbol(), "EURUSD", "snapshot A retains its own symbol", tests_run, tests_failed);
   AssertEqualString(context_b.Symbol(), "GBPUSD", "snapshot B retains its own symbol", tests_run, tests_failed);
   AssertEqualLong((long)context_a.CycleId(), 1, "snapshot A retains its own cycle id", tests_run, tests_failed);
   AssertEqualLong((long)context_b.CycleId(), 2, "snapshot B retains its own cycle id", tests_run, tests_failed);
   AssertEqualDouble(context_a.Tick().bid, 1.10534, "snapshot A tick bid unaffected by snapshot B", tests_run, tests_failed);

   // Mutate the source tick variable after construction; the published
   // snapshot must not observe the change.
   tick_a.bid = 9.99999;
   tick_a.ask = 9.99999;
   AssertEqualDouble(context_a.Tick().bid, 1.10534, "snapshot A tick bid unaffected by later source mutation", tests_run, tests_failed);
   AssertEqualDouble(context_a.Tick().ask, 1.10551, "snapshot A tick ask unaffected by later source mutation", tests_run, tests_failed);
}

void TestRuntimeIdentityUsage(int &tests_run, int &tests_failed)
{
   CQuantumRuntimeIdentity identity;
   CQuantumMarketContext context;
   SQuantumResult result;
   InitializeIdentity(identity, "EURUSD");
   const string original_symbol = identity.Symbol();
   const long original_magic = identity.MagicNumber();
   MqlTick tick = MakeTick(1.10534, 1.10551, D'2026.01.05 08:30:00');

   context.Initialize(identity, PERIOD_M15, 1, tick, 10000.0, 10000.0, result);

   AssertEqualString(context.Symbol(), identity.Symbol(), "context symbol matches RuntimeIdentity symbol", tests_run, tests_failed);
   AssertEqualBool(identity.IsInitialized(), true, "RuntimeIdentity remains initialized after MarketContext construction", tests_run, tests_failed);
   AssertEqualString(identity.Symbol(), original_symbol, "RuntimeIdentity symbol not mutated by MarketContext", tests_run, tests_failed);
   AssertEqualLong(identity.MagicNumber(), original_magic, "RuntimeIdentity magic number not mutated by MarketContext", tests_run, tests_failed);
}

void TestDeterminism(int &tests_run, int &tests_failed)
{
   CQuantumRuntimeIdentity identity_one;
   CQuantumRuntimeIdentity identity_two;
   CQuantumMarketContext context_one;
   CQuantumMarketContext context_two;
   SQuantumResult result_one;
   SQuantumResult result_two;
   InitializeIdentity(identity_one, "EURUSD");
   InitializeIdentity(identity_two, "EURUSD");
   MqlTick tick_one = MakeTick(1.10534, 1.10551, D'2026.01.05 08:30:00');
   MqlTick tick_two = MakeTick(1.10534, 1.10551, D'2026.01.05 08:30:00');

   context_one.Initialize(identity_one, PERIOD_M15, 7, tick_one, 10250.75, 10180.40, result_one);
   context_two.Initialize(identity_two, PERIOD_M15, 7, tick_two, 10250.75, 10180.40, result_two);

   AssertEqualString(context_one.Symbol(), context_two.Symbol(), "identical inputs produce identical symbol", tests_run, tests_failed);
   AssertEqualLong((long)context_one.Timeframe(), (long)context_two.Timeframe(), "identical inputs produce identical timeframe", tests_run, tests_failed);
   AssertEqualLong((long)context_one.CycleId(), (long)context_two.CycleId(), "identical inputs produce identical cycle id", tests_run, tests_failed);
   AssertEqualDouble(context_one.Tick().bid, context_two.Tick().bid, "identical inputs produce identical tick bid", tests_run, tests_failed);
   AssertEqualDouble(context_one.Tick().ask, context_two.Tick().ask, "identical inputs produce identical tick ask", tests_run, tests_failed);
   AssertEqualDouble(context_one.AccountBalance(), context_two.AccountBalance(), "identical inputs produce identical account balance", tests_run, tests_failed);
   AssertEqualDouble(context_one.AccountEquity(), context_two.AccountEquity(), "identical inputs produce identical account equity", tests_run, tests_failed);
}

void OnStart()
{
   int tests_run = 0;
   int tests_failed = 0;

   TestInitialState(tests_run, tests_failed);
   TestInvalidRuntimeIdentityRejected(tests_run, tests_failed);
   TestInvalidTimeframeRejected(tests_run, tests_failed);
   TestInvalidCycleIdRejected(tests_run, tests_failed);
   TestInvalidTickRejected(tests_run, tests_failed);
   TestValidConstruction(tests_run, tests_failed);
   TestImmutabilityAfterPublish(tests_run, tests_failed);
   TestSnapshotIsolation(tests_run, tests_failed);
   TestRuntimeIdentityUsage(tests_run, tests_failed);
   TestDeterminism(tests_run, tests_failed);

   if(tests_failed > 0)
   {
      Print("Project Quantum Phase 1.4 market context tests failed: ", tests_failed, "/", tests_run);
      return;
   }

   Print("Project Quantum Phase 1.4 market context tests passed: ", tests_run, "/", tests_run);
}