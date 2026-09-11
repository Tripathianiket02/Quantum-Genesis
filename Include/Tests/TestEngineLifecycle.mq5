#property script_show_inputs

#include "../Core/EngineLifecycle.mqh"

//+------------------------------------------------------------------+
//| Project Quantum — Phase 1.3 Engine Lifecycle Checks              |
//+------------------------------------------------------------------+

void AssertEqualBool(const bool actual, const bool expected, const string test_name,
                     int &tests_run, int &tests_failed)
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

void AssertEqualLong(const long actual, const long expected, const string test_name,
                     int &tests_run, int &tests_failed)
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

void AssertEqualString(const string actual, const string expected, const string test_name,
                       int &tests_run, int &tests_failed)
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

void InitializeIdentity(CQuantumRuntimeIdentity &identity)
{
   SQuantumResult result;
   identity.Initialize("Q01", "LifecycleTest", "EURUSD", result);
}

void TestInitialState(int &tests_run, int &tests_failed)
{
   CQuantumEngineLifecycle lifecycle;
   AssertEqualLong((long)lifecycle.State(), (long)QUANTUM_ENGINE_STATE_CREATED, "new lifecycle is created", tests_run, tests_failed);
   AssertEqualBool(lifecycle.IsInitialized(), false, "new lifecycle is not initialized", tests_run, tests_failed);
   AssertEqualBool(lifecycle.IsRunning(), false, "new lifecycle is not running", tests_run, tests_failed);
   AssertEqualString(QuantumEngineLifecycleStateToString(lifecycle.State()), "CREATED", "created state name", tests_run, tests_failed);
}

void TestInitialization(int &tests_run, int &tests_failed)
{
   CQuantumRuntimeIdentity identity;
   CQuantumEngineLifecycle lifecycle;
   CQuantumEngineLifecycle equivalent_lifecycle;
   SQuantumResult result;
   SQuantumResult equivalent_result;
   InitializeIdentity(identity);

   AssertEqualBool(lifecycle.Initialize(identity, result), true, "valid lifecycle initialization succeeds", tests_run, tests_failed);
   AssertEqualBool(result.IsOk(), true, "valid lifecycle initialization result ok", tests_run, tests_failed);
   AssertEqualLong((long)result.Component, (long)QUANTUM_COMPONENT_ENGINE, "initialization result component", tests_run, tests_failed);
   AssertEqualLong((long)lifecycle.State(), (long)QUANTUM_ENGINE_STATE_INITIALIZED, "initialization changes state", tests_run, tests_failed);
   AssertEqualBool(lifecycle.IsInitialized(), true, "initialized lifecycle reports initialized", tests_run, tests_failed);
   AssertEqualBool(lifecycle.IsRunning(), false, "initialized lifecycle is not running", tests_run, tests_failed);
   AssertEqualBool(equivalent_lifecycle.Initialize(identity, equivalent_result), true, "equivalent lifecycle initialization succeeds", tests_run, tests_failed);
   AssertEqualLong((long)equivalent_lifecycle.State(), (long)lifecycle.State(), "initialization is deterministic", tests_run, tests_failed);

   result.Reset();
   AssertEqualBool(lifecycle.Initialize(identity, result), false, "repeated initialization rejected", tests_run, tests_failed);
   AssertEqualLong((long)result.Status, (long)QUANTUM_STATUS_BLOCKED, "repeated initialization status blocked", tests_run, tests_failed);
   AssertEqualLong((long)result.ErrorCode, (long)QUANTUM_ERROR_INVALID_STATE, "repeated initialization error code", tests_run, tests_failed);
}

void TestInvalidInitialization(int &tests_run, int &tests_failed)
{
   CQuantumRuntimeIdentity uninitialized_identity;
   CQuantumEngineLifecycle lifecycle;
   SQuantumResult result;

   AssertEqualBool(lifecycle.Initialize(uninitialized_identity, result), false, "uninitialized runtime identity rejected", tests_run, tests_failed);
   AssertEqualLong((long)result.Status, (long)QUANTUM_STATUS_ERROR, "uninitialized identity status error", tests_run, tests_failed);
   AssertEqualLong((long)result.ErrorCode, (long)QUANTUM_ERROR_NOT_INITIALIZED, "uninitialized identity error code", tests_run, tests_failed);
   AssertEqualLong((long)lifecycle.State(), (long)QUANTUM_ENGINE_STATE_CREATED, "failed initialization preserves created state", tests_run, tests_failed);
}

void TestStartAndStop(int &tests_run, int &tests_failed)
{
   CQuantumRuntimeIdentity identity;
   CQuantumEngineLifecycle lifecycle;
   SQuantumResult result;
   InitializeIdentity(identity);
   lifecycle.Initialize(identity, result);

   result.Reset();
   AssertEqualBool(lifecycle.Start(result), true, "valid start succeeds", tests_run, tests_failed);
   AssertEqualBool(result.IsOk(), true, "valid start result ok", tests_run, tests_failed);
   AssertEqualLong((long)lifecycle.State(), (long)QUANTUM_ENGINE_STATE_RUNNING, "start changes state", tests_run, tests_failed);
   AssertEqualBool(lifecycle.IsRunning(), true, "running lifecycle reports running", tests_run, tests_failed);

   result.Reset();
   AssertEqualBool(lifecycle.Start(result), false, "repeated start rejected", tests_run, tests_failed);
   AssertEqualLong((long)result.Status, (long)QUANTUM_STATUS_BLOCKED, "repeated start status blocked", tests_run, tests_failed);
   AssertEqualLong((long)result.ErrorCode, (long)QUANTUM_ERROR_INVALID_STATE, "repeated start error code", tests_run, tests_failed);

   result.Reset();
   AssertEqualBool(lifecycle.Stop(result), true, "valid stop succeeds", tests_run, tests_failed);
   AssertEqualBool(result.IsOk(), true, "valid stop result ok", tests_run, tests_failed);
   AssertEqualLong((long)lifecycle.State(), (long)QUANTUM_ENGINE_STATE_STOPPED, "stop changes state", tests_run, tests_failed);
   AssertEqualBool(lifecycle.IsInitialized(), true, "stopped lifecycle remains initialized", tests_run, tests_failed);
   AssertEqualBool(lifecycle.IsRunning(), false, "stopped lifecycle is not running", tests_run, tests_failed);

   result.Reset();
   AssertEqualBool(lifecycle.Stop(result), false, "repeated stop rejected", tests_run, tests_failed);
   AssertEqualLong((long)result.ErrorCode, (long)QUANTUM_ERROR_INVALID_STATE, "repeated stop error code", tests_run, tests_failed);
}

void TestInvalidTransitions(int &tests_run, int &tests_failed)
{
   CQuantumRuntimeIdentity identity;
   CQuantumEngineLifecycle lifecycle;
   SQuantumResult result;
   InitializeIdentity(identity);

   AssertEqualBool(lifecycle.Start(result), false, "start before initialization rejected", tests_run, tests_failed);
   AssertEqualLong((long)result.ErrorCode, (long)QUANTUM_ERROR_NOT_INITIALIZED, "start before initialization error code", tests_run, tests_failed);
   result.Reset();
   AssertEqualBool(lifecycle.Stop(result), false, "stop before start rejected", tests_run, tests_failed);
   AssertEqualLong((long)result.ErrorCode, (long)QUANTUM_ERROR_INVALID_STATE, "stop before start error code", tests_run, tests_failed);

   result.Reset();
   lifecycle.Initialize(identity, result);
   result.Reset();
   AssertEqualBool(lifecycle.Stop(result), false, "stop before running rejected", tests_run, tests_failed);
   AssertEqualLong((long)result.ErrorCode, (long)QUANTUM_ERROR_INVALID_STATE, "stop before running error code", tests_run, tests_failed);

   lifecycle.Start(result);
   result.Reset();
   AssertEqualBool(lifecycle.Initialize(identity, result), false, "running lifecycle cannot initialize", tests_run, tests_failed);
   AssertEqualLong((long)result.ErrorCode, (long)QUANTUM_ERROR_INVALID_STATE, "running initialization error code", tests_run, tests_failed);
}

void TestTerminalStateAndIsolation(int &tests_run, int &tests_failed)
{
   CQuantumRuntimeIdentity identity;
   CQuantumEngineLifecycle first;
   CQuantumEngineLifecycle second;
   SQuantumResult result;
   InitializeIdentity(identity);
   first.Initialize(identity, result);
   first.Start(result);
   first.Stop(result);

   result.Reset();
   AssertEqualBool(first.Start(result), false, "stopped lifecycle cannot restart", tests_run, tests_failed);
   AssertEqualLong((long)result.ErrorCode, (long)QUANTUM_ERROR_INVALID_STATE, "restart error code", tests_run, tests_failed);
   result.Reset();
   AssertEqualBool(first.Initialize(identity, result), false, "stopped lifecycle cannot reinitialize", tests_run, tests_failed);
   AssertEqualLong((long)first.State(), (long)QUANTUM_ENGINE_STATE_STOPPED, "failed terminal transitions preserve stopped state", tests_run, tests_failed);
   AssertEqualLong((long)second.State(), (long)QUANTUM_ENGINE_STATE_CREATED, "independent lifecycle retains created state", tests_run, tests_failed);
}

void TestRuntimeIdentityIsNotMutated(int &tests_run, int &tests_failed)
{
   CQuantumRuntimeIdentity identity;
   CQuantumEngineLifecycle lifecycle;
   SQuantumResult result;
   InitializeIdentity(identity);
   const string original_symbol = identity.Symbol();
   const long original_magic = identity.MagicNumber();

   lifecycle.Initialize(identity, result);
   lifecycle.Start(result);
   lifecycle.Stop(result);

   AssertEqualString(identity.Symbol(), original_symbol, "lifecycle does not mutate runtime identity symbol", tests_run, tests_failed);
   AssertEqualLong(identity.MagicNumber(), original_magic, "lifecycle does not mutate runtime identity magic", tests_run, tests_failed);
   AssertEqualBool(identity.IsInitialized(), true, "lifecycle preserves runtime identity initialization", tests_run, tests_failed);
}

void OnStart()
{
   int tests_run = 0;
   int tests_failed = 0;

   TestInitialState(tests_run, tests_failed);
   TestInitialization(tests_run, tests_failed);
   TestInvalidInitialization(tests_run, tests_failed);
   TestStartAndStop(tests_run, tests_failed);
   TestInvalidTransitions(tests_run, tests_failed);
   TestTerminalStateAndIsolation(tests_run, tests_failed);
   TestRuntimeIdentityIsNotMutated(tests_run, tests_failed);

   if(tests_failed > 0)
   {
      Print("Project Quantum Phase 1.3 engine lifecycle tests failed: ", tests_failed, "/", tests_run);
      return;
   }

   Print("Project Quantum Phase 1.3 engine lifecycle tests passed: ", tests_run, "/", tests_run);
}
