#property script_show_inputs

#include "../Core/Config.mqh"

//+------------------------------------------------------------------+
//| Project Quantum — Phase 1.5 Configuration Checks                  |
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

void TestInitialState(int &tests_run, int &tests_failed)
{
   CQuantumConfig config;

   AssertEqualBool(config.IsInitialized(), false, "new config is not initialized", tests_run, tests_failed);
   AssertEqualString(config.Symbol(), "", "new config symbol is empty", tests_run, tests_failed);
   AssertEqualString(config.StrategyID(), "", "new config strategy id is empty", tests_run, tests_failed);
   AssertEqualString(config.InstanceID(), "", "new config instance id is empty", tests_run, tests_failed);
   AssertEqualLong((long)config.WorkingTimeframe(), (long)PERIOD_CURRENT, "new config working timeframe is PERIOD_CURRENT", tests_run, tests_failed);
}

void TestValidInitialization(int &tests_run, int &tests_failed)
{
   CQuantumConfig config;
   SQuantumResult result;

   AssertEqualBool(config.Initialize("EURUSD", "QuantumCore", "Primary", PERIOD_M15, result),
                   true, "valid Config initialization succeeds", tests_run, tests_failed);
   AssertEqualBool(result.IsOk(), true, "valid initialization result ok", tests_run, tests_failed);
   AssertEqualLong((long)result.Component, (long)QUANTUM_COMPONENT_CONFIGURATION, "valid initialization result component", tests_run, tests_failed);
   AssertEqualBool(config.IsInitialized(), true, "initialized config reports initialized", tests_run, tests_failed);
   AssertEqualString(config.Symbol(), "EURUSD", "initialized config symbol correct", tests_run, tests_failed);
   AssertEqualString(config.StrategyID(), "QuantumCore", "initialized config strategy id correct", tests_run, tests_failed);
   AssertEqualString(config.InstanceID(), "Primary", "initialized config instance id correct", tests_run, tests_failed);
   AssertEqualLong((long)config.WorkingTimeframe(), (long)PERIOD_M15, "initialized config working timeframe correct", tests_run, tests_failed);
}

void TestInvalidRequiredValuesRejected(int &tests_run, int &tests_failed)
{
   SQuantumResult result;

   CQuantumConfig empty_symbol_config;
   AssertEqualBool(empty_symbol_config.Initialize("", "QuantumCore", "Primary", PERIOD_M15, result),
                   false, "empty symbol rejected", tests_run, tests_failed);
   AssertEqualLong((long)result.ErrorCode, (long)QUANTUM_ERROR_INVALID_ARGUMENT, "empty symbol error code", tests_run, tests_failed);

   result.Reset();
   CQuantumConfig whitespace_symbol_config;
   AssertEqualBool(whitespace_symbol_config.Initialize(" EURUSD", "QuantumCore", "Primary", PERIOD_M15, result),
                   false, "whitespace symbol rejected", tests_run, tests_failed);
   AssertEqualLong((long)result.ErrorCode, (long)QUANTUM_ERROR_INVALID_ARGUMENT, "whitespace symbol error code", tests_run, tests_failed);

   result.Reset();
   CQuantumConfig empty_strategy_config;
   AssertEqualBool(empty_strategy_config.Initialize("EURUSD", "", "Primary", PERIOD_M15, result),
                   false, "empty strategy id rejected", tests_run, tests_failed);
   AssertEqualLong((long)result.ErrorCode, (long)QUANTUM_ERROR_INVALID_ARGUMENT, "empty strategy id error code", tests_run, tests_failed);

   result.Reset();
   CQuantumConfig whitespace_strategy_config;
   AssertEqualBool(whitespace_strategy_config.Initialize("EURUSD", "QuantumCore ", "Primary", PERIOD_M15, result),
                   false, "whitespace strategy id rejected", tests_run, tests_failed);
   AssertEqualLong((long)result.ErrorCode, (long)QUANTUM_ERROR_INVALID_ARGUMENT, "whitespace strategy id error code", tests_run, tests_failed);

   result.Reset();
   CQuantumConfig empty_instance_config;
   AssertEqualBool(empty_instance_config.Initialize("EURUSD", "QuantumCore", "", PERIOD_M15, result),
                   false, "empty instance id rejected", tests_run, tests_failed);
   AssertEqualLong((long)result.ErrorCode, (long)QUANTUM_ERROR_INVALID_ARGUMENT, "empty instance id error code", tests_run, tests_failed);

   result.Reset();
   CQuantumConfig whitespace_instance_config;
   AssertEqualBool(whitespace_instance_config.Initialize("EURUSD", "QuantumCore", "Primary ", PERIOD_M15, result),
                   false, "whitespace instance id rejected", tests_run, tests_failed);
   AssertEqualLong((long)result.ErrorCode, (long)QUANTUM_ERROR_INVALID_ARGUMENT, "whitespace instance id error code", tests_run, tests_failed);

   AssertEqualBool(empty_symbol_config.IsInitialized(), false, "rejected required value leaves config uninitialized", tests_run, tests_failed);
}

void TestInvalidTimeframeRejected(int &tests_run, int &tests_failed)
{
   CQuantumConfig config;
   SQuantumResult result;

   AssertEqualBool(config.Initialize("EURUSD", "QuantumCore", "Primary", PERIOD_CURRENT, result),
                   false, "PERIOD_CURRENT working timeframe rejected", tests_run, tests_failed);
   AssertEqualLong((long)result.ErrorCode, (long)QUANTUM_ERROR_INVALID_ARGUMENT, "invalid timeframe error code", tests_run, tests_failed);
   AssertEqualBool(config.IsInitialized(), false, "config remains uninitialized after rejected timeframe", tests_run, tests_failed);
}

void TestFailedInitializationDoesNotPublish(int &tests_run, int &tests_failed)
{
   CQuantumConfig config;
   SQuantumResult result;

   config.Initialize("", "QuantumCore", "Primary", PERIOD_M15, result);

   AssertEqualBool(config.IsInitialized(), false, "failed initialization leaves IsInitialized false", tests_run, tests_failed);
   AssertEqualString(config.Symbol(), "", "failed initialization does not partially publish symbol", tests_run, tests_failed);
   AssertEqualString(config.StrategyID(), "", "failed initialization does not partially publish strategy id", tests_run, tests_failed);
   AssertEqualString(config.InstanceID(), "", "failed initialization does not partially publish instance id", tests_run, tests_failed);
   AssertEqualLong((long)config.WorkingTimeframe(), (long)PERIOD_CURRENT, "failed initialization does not partially publish timeframe", tests_run, tests_failed);
}

void TestResultDetailsForRepresentativeFailures(int &tests_run, int &tests_failed)
{
   CQuantumConfig missing_field_config;
   SQuantumResult missing_field_result;
   missing_field_config.Initialize("", "QuantumCore", "Primary", PERIOD_M15, missing_field_result);

   AssertEqualLong((long)missing_field_result.Status, (long)QUANTUM_STATUS_ERROR, "missing-field failure status is ERROR", tests_run, tests_failed);
   AssertEqualLong((long)missing_field_result.ErrorCode, (long)QUANTUM_ERROR_INVALID_ARGUMENT, "missing-field failure error code is INVALID_ARGUMENT", tests_run, tests_failed);
   AssertEqualLong((long)missing_field_result.Component, (long)QUANTUM_COMPONENT_CONFIGURATION, "missing-field failure component is CONFIGURATION", tests_run, tests_failed);

   CQuantumConfig published_config;
   SQuantumResult first_result;
   SQuantumResult second_result;
   published_config.Initialize("EURUSD", "QuantumCore", "Primary", PERIOD_M15, first_result);
   published_config.Initialize("GBPUSD", "QuantumAlt", "Secondary", PERIOD_H1, second_result);

   AssertEqualLong((long)second_result.Status, (long)QUANTUM_STATUS_BLOCKED, "re-initialization failure status is BLOCKED", tests_run, tests_failed);
   AssertEqualLong((long)second_result.ErrorCode, (long)QUANTUM_ERROR_INVALID_STATE, "re-initialization failure error code is INVALID_STATE", tests_run, tests_failed);
   AssertEqualLong((long)second_result.Component, (long)QUANTUM_COMPONENT_CONFIGURATION, "re-initialization failure component is CONFIGURATION", tests_run, tests_failed);
}

void TestImmutabilityAfterPublish(int &tests_run, int &tests_failed)
{
   CQuantumConfig config;
   SQuantumResult result;

   AssertEqualBool(config.Initialize("EURUSD", "QuantumCore", "Primary", PERIOD_M15, result),
                   true, "first initialization succeeds", tests_run, tests_failed);

   result.Reset();
   AssertEqualBool(config.Initialize("GBPUSD", "QuantumAlt", "Secondary", PERIOD_H1, result),
                   false, "re-initializing a published config is rejected", tests_run, tests_failed);
   AssertEqualLong((long)result.Status, (long)QUANTUM_STATUS_BLOCKED, "re-initialization status blocked", tests_run, tests_failed);
   AssertEqualLong((long)result.ErrorCode, (long)QUANTUM_ERROR_INVALID_STATE, "re-initialization error code", tests_run, tests_failed);

   AssertEqualString(config.Symbol(), "EURUSD", "symbol unchanged after rejected re-initialization", tests_run, tests_failed);
   AssertEqualString(config.StrategyID(), "QuantumCore", "strategy id unchanged after rejected re-initialization", tests_run, tests_failed);
   AssertEqualString(config.InstanceID(), "Primary", "instance id unchanged after rejected re-initialization", tests_run, tests_failed);
   AssertEqualLong((long)config.WorkingTimeframe(), (long)PERIOD_M15, "working timeframe unchanged after rejected re-initialization", tests_run, tests_failed);
}

void TestDeterminism(int &tests_run, int &tests_failed)
{
   CQuantumConfig config_one;
   CQuantumConfig config_two;
   SQuantumResult result_one;
   SQuantumResult result_two;

   config_one.Initialize("EURUSD", "QuantumCore", "Primary", PERIOD_M15, result_one);
   config_two.Initialize("EURUSD", "QuantumCore", "Primary", PERIOD_M15, result_two);

   AssertEqualString(config_one.Symbol(), config_two.Symbol(), "identical inputs produce identical symbol", tests_run, tests_failed);
   AssertEqualString(config_one.StrategyID(), config_two.StrategyID(), "identical inputs produce identical strategy id", tests_run, tests_failed);
   AssertEqualString(config_one.InstanceID(), config_two.InstanceID(), "identical inputs produce identical instance id", tests_run, tests_failed);
   AssertEqualLong((long)config_one.WorkingTimeframe(), (long)config_two.WorkingTimeframe(), "identical inputs produce identical working timeframe", tests_run, tests_failed);
   AssertEqualBool(result_one.IsOk(), result_two.IsOk(), "identical inputs produce identical result status", tests_run, tests_failed);
}

void TestInstanceDistinguishabilityAndIsolation(int &tests_run, int &tests_failed)
{
   CQuantumConfig config_a;
   CQuantumConfig config_b;
   SQuantumResult result;
   string symbol_a = "EURUSD";

   config_a.Initialize(symbol_a, "QuantumCore", "Primary", PERIOD_M15, result);
   result.Reset();
   config_b.Initialize("GBPUSD", "QuantumAlt", "Secondary", PERIOD_H1, result);

   AssertEqualString(config_a.Symbol(), "EURUSD", "config A retains its own symbol", tests_run, tests_failed);
   AssertEqualString(config_b.Symbol(), "GBPUSD", "config B retains its own, distinguishable symbol", tests_run, tests_failed);
   AssertEqualString(config_a.StrategyID(), "QuantumCore", "config A retains its own strategy id", tests_run, tests_failed);
   AssertEqualString(config_b.StrategyID(), "QuantumAlt", "config B retains its own, distinguishable strategy id", tests_run, tests_failed);
   AssertEqualLong((long)config_a.WorkingTimeframe(), (long)PERIOD_M15, "config A retains its own working timeframe", tests_run, tests_failed);
   AssertEqualLong((long)config_b.WorkingTimeframe(), (long)PERIOD_H1, "config B retains its own, distinguishable working timeframe", tests_run, tests_failed);

   // Mutate the source variable after construction; the published
   // configuration must not observe the change.
   symbol_a = "CHANGED";
   AssertEqualString(config_a.Symbol(), "EURUSD", "config A symbol unaffected by later source mutation", tests_run, tests_failed);
   AssertEqualString(config_b.Symbol(), "GBPUSD", "config B unaffected by config A's source mutation", tests_run, tests_failed);
}

void OnStart()
{
   int tests_run = 0;
   int tests_failed = 0;

   TestInitialState(tests_run, tests_failed);
   TestValidInitialization(tests_run, tests_failed);
   TestInvalidRequiredValuesRejected(tests_run, tests_failed);
   TestInvalidTimeframeRejected(tests_run, tests_failed);
   TestFailedInitializationDoesNotPublish(tests_run, tests_failed);
   TestResultDetailsForRepresentativeFailures(tests_run, tests_failed);
   TestImmutabilityAfterPublish(tests_run, tests_failed);
   TestDeterminism(tests_run, tests_failed);
   TestInstanceDistinguishabilityAndIsolation(tests_run, tests_failed);

   if(tests_failed > 0)
   {
      Print("Project Quantum Phase 1.5 configuration tests failed: ", tests_failed, "/", tests_run);
      return;
   }

   Print("Project Quantum Phase 1.5 configuration tests passed: ", tests_run, "/", tests_run);
}