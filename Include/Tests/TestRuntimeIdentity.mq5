#property script_show_inputs

#include "../Core/RuntimeIdentity.mqh"

//+------------------------------------------------------------------+
//| Project Quantum — Phase 1.2 Runtime Identity Checks               |
//+------------------------------------------------------------------+

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

void AssertNotEqualLong(const long actual,
                        const long unexpected,
                        const string test_name,
                        int &tests_run,
                        int &tests_failed)
{
   tests_run++;

   if(actual == unexpected)
   {
      tests_failed++;
      Print("FAIL: ", test_name, " unexpected=", unexpected);
      return;
   }

   Print("PASS: ", test_name);
}

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

void TestValidInitialization(int &tests_run, int &tests_failed)
{
   SQuantumResult result;
   CQuantumRuntimeIdentity identity;

   AssertEqualBool(identity.Initialize("Q01", "A", "EURUSD", result), true, "valid identity initializes", tests_run, tests_failed);
   AssertEqualBool(identity.IsInitialized(), true, "identity initialized flag", tests_run, tests_failed);
   AssertEqualString(identity.StrategyID(), "Q01", "strategy id preserved", tests_run, tests_failed);
   AssertEqualString(identity.InstanceID(), "A", "instance id preserved", tests_run, tests_failed);
   AssertEqualString(identity.Symbol(), "EURUSD", "symbol preserved", tests_run, tests_failed);
   AssertEqualBool(identity.MagicNumber() > 0, true, "magic number positive", tests_run, tests_failed);
   AssertEqualBool(result.IsOk(), true, "valid initialization result ok", tests_run, tests_failed);
}

void TestInvalidInitialization(int &tests_run, int &tests_failed)
{
   SQuantumResult result;
   CQuantumRuntimeIdentity identity;

   AssertEqualBool(identity.Initialize("", "A", "EURUSD", result), false, "empty strategy rejected", tests_run, tests_failed);
   AssertEqualBool(result.HasFailure(), true, "empty strategy explicit failure", tests_run, tests_failed);
   AssertEqualString(QuantumErrorCodeToString(result.ErrorCode), "INVALID_ARGUMENT", "empty strategy error code", tests_run, tests_failed);

   result.Reset();
   AssertEqualBool(identity.Initialize("Q01", "", "EURUSD", result), false, "empty instance rejected", tests_run, tests_failed);
   AssertEqualBool(result.HasFailure(), true, "empty instance explicit failure", tests_run, tests_failed);

   result.Reset();
   AssertEqualBool(identity.Initialize("Q01", "A", "", result), false, "empty symbol rejected", tests_run, tests_failed);
   AssertEqualBool(result.HasFailure(), true, "empty symbol explicit failure", tests_run, tests_failed);
}

void TestWhitespaceInitialization(int &tests_run, int &tests_failed)
{
   SQuantumResult result;
   CQuantumRuntimeIdentity identity;

   AssertEqualBool(identity.Initialize(" Q01", "A", "EURUSD", result), false, "leading strategy whitespace rejected", tests_run, tests_failed);
   AssertEqualLong((long)result.Status, (long)QUANTUM_STATUS_ERROR, "strategy whitespace status error", tests_run, tests_failed);
   AssertEqualLong((long)result.ErrorCode, (long)QUANTUM_ERROR_INVALID_ARGUMENT, "strategy whitespace error code", tests_run, tests_failed);
   AssertEqualBool(identity.IsInitialized(), false, "strategy whitespace leaves identity uninitialized", tests_run, tests_failed);

   result.Reset();
   AssertEqualBool(identity.Initialize("Q01 ", "A", "EURUSD", result), false, "trailing strategy whitespace rejected", tests_run, tests_failed);
   AssertEqualLong((long)result.ErrorCode, (long)QUANTUM_ERROR_INVALID_ARGUMENT, "trailing strategy whitespace error code", tests_run, tests_failed);
   AssertEqualBool(identity.IsInitialized(), false, "trailing strategy whitespace leaves identity uninitialized", tests_run, tests_failed);

   result.Reset();
   AssertEqualBool(identity.Initialize("Q01", " A", "EURUSD", result), false, "leading instance whitespace rejected", tests_run, tests_failed);
   AssertEqualLong((long)result.ErrorCode, (long)QUANTUM_ERROR_INVALID_ARGUMENT, "leading instance whitespace error code", tests_run, tests_failed);
   AssertEqualBool(identity.IsInitialized(), false, "leading instance whitespace leaves identity uninitialized", tests_run, tests_failed);

   result.Reset();
   AssertEqualBool(identity.Initialize("Q01", "A ", "EURUSD", result), false, "trailing instance whitespace rejected", tests_run, tests_failed);
   AssertEqualLong((long)result.Status, (long)QUANTUM_STATUS_ERROR, "instance whitespace status error", tests_run, tests_failed);
   AssertEqualLong((long)result.ErrorCode, (long)QUANTUM_ERROR_INVALID_ARGUMENT, "instance whitespace error code", tests_run, tests_failed);
   AssertEqualBool(identity.IsInitialized(), false, "instance whitespace leaves identity uninitialized", tests_run, tests_failed);

   result.Reset();
   AssertEqualBool(identity.Initialize("Q01", "A", " EURUSD", result), false, "leading symbol whitespace rejected", tests_run, tests_failed);
   AssertEqualLong((long)result.Status, (long)QUANTUM_STATUS_ERROR, "symbol whitespace status error", tests_run, tests_failed);
   AssertEqualLong((long)result.ErrorCode, (long)QUANTUM_ERROR_INVALID_ARGUMENT, "symbol whitespace error code", tests_run, tests_failed);
   AssertEqualBool(identity.IsInitialized(), false, "symbol whitespace leaves identity uninitialized", tests_run, tests_failed);

   result.Reset();
   AssertEqualBool(identity.Initialize("Q01", "A", "EURUSD ", result), false, "trailing symbol whitespace rejected", tests_run, tests_failed);
   AssertEqualLong((long)result.ErrorCode, (long)QUANTUM_ERROR_INVALID_ARGUMENT, "trailing symbol whitespace error code", tests_run, tests_failed);
   AssertEqualBool(identity.IsInitialized(), false, "trailing symbol whitespace leaves identity uninitialized", tests_run, tests_failed);
}

void TestDeterminismAndDistinguishability(int &tests_run, int &tests_failed)
{
   SQuantumResult result_a;
   SQuantumResult result_b;
   SQuantumResult result_c;
   SQuantumResult result_d;
   SQuantumResult result_e;

   CQuantumRuntimeIdentity identity_a;
   CQuantumRuntimeIdentity identity_b;
   CQuantumRuntimeIdentity identity_c;
   CQuantumRuntimeIdentity identity_d;
   CQuantumRuntimeIdentity identity_e;

   identity_a.Initialize("Q01", "A", "EURUSD", result_a);
   identity_b.Initialize("Q01", "A", "EURUSD", result_b);
   identity_c.Initialize("Q01", "B", "EURUSD", result_c);
   identity_d.Initialize("Q02", "A", "EURUSD", result_d);
   identity_e.Initialize("Q01", "A", "GBPUSD", result_e);

   AssertEqualLong(identity_a.MagicNumber(), identity_b.MagicNumber(), "same inputs produce same magic", tests_run, tests_failed);
   AssertEqualBool(identity_a.SameRuntimeAs(identity_b), true, "same inputs same runtime identity", tests_run, tests_failed);
   AssertNotEqualLong(identity_a.MagicNumber(), identity_c.MagicNumber(), "different instance changes magic", tests_run, tests_failed);
   AssertNotEqualLong(identity_a.MagicNumber(), identity_d.MagicNumber(), "different strategy changes magic", tests_run, tests_failed);
   AssertNotEqualLong(identity_a.MagicNumber(), identity_e.MagicNumber(), "different symbol changes magic", tests_run, tests_failed);
   AssertEqualString(identity_c.Symbol(), "EURUSD", "same symbol preserved for different instance", tests_run, tests_failed);
   AssertEqualBool(identity_a.MatchesOwnership("EURUSD", identity_a.MagicNumber()), true, "symbol and magic ownership match", tests_run, tests_failed);
   AssertEqualBool(identity_a.MatchesOwnership("EURUSD", identity_c.MagicNumber()), false, "symbol alone is insufficient", tests_run, tests_failed);
}

void TestRetryAfterFailedInitialization(int &tests_run, int &tests_failed)
{
   SQuantumResult result;
   SQuantumResult expected_result;
   CQuantumRuntimeIdentity identity;
   CQuantumRuntimeIdentity expected_identity;

   AssertEqualBool(identity.Initialize("", "A", "EURUSD", result), false, "failed initialization before retry", tests_run, tests_failed);
   AssertEqualBool(identity.IsInitialized(), false, "failed initialization does not set initialized flag", tests_run, tests_failed);
   AssertEqualString(identity.StrategyID(), "", "failed initialization preserves empty strategy state", tests_run, tests_failed);
   AssertEqualString(identity.InstanceID(), "", "failed initialization preserves empty instance state", tests_run, tests_failed);
   AssertEqualString(identity.Symbol(), "", "failed initialization preserves empty symbol state", tests_run, tests_failed);
   AssertEqualLong(identity.MagicNumber(), 0, "failed initialization preserves zero magic", tests_run, tests_failed);

   result.Reset();
   AssertEqualBool(identity.Initialize("Q01", "A", "EURUSD", result), true, "valid retry initializes identity", tests_run, tests_failed);
   expected_identity.Initialize("Q01", "A", "EURUSD", expected_result);
   AssertEqualBool(identity.IsInitialized(), true, "valid retry sets initialized flag", tests_run, tests_failed);
   AssertEqualString(identity.StrategyID(), "Q01", "valid retry stores strategy", tests_run, tests_failed);
   AssertEqualString(identity.InstanceID(), "A", "valid retry stores instance", tests_run, tests_failed);
   AssertEqualString(identity.Symbol(), "EURUSD", "valid retry stores symbol", tests_run, tests_failed);
   AssertEqualLong(identity.MagicNumber(), expected_identity.MagicNumber(), "valid retry magic is deterministic", tests_run, tests_failed);
}

void TestUninitializedComparisons(int &tests_run, int &tests_failed)
{
   SQuantumResult result;
   CQuantumRuntimeIdentity initialized_identity;
   CQuantumRuntimeIdentity uninitialized_identity;

   initialized_identity.Initialize("Q01", "A", "EURUSD", result);

   AssertEqualBool(uninitialized_identity.MatchesOwnership("EURUSD", initialized_identity.MagicNumber()), false, "uninitialized identity never matches ownership", tests_run, tests_failed);
   AssertEqualBool(uninitialized_identity.SameRuntimeAs(initialized_identity), false, "uninitialized identity differs from initialized identity", tests_run, tests_failed);
   AssertEqualBool(initialized_identity.SameRuntimeAs(uninitialized_identity), false, "initialized identity differs from uninitialized identity", tests_run, tests_failed);
   AssertEqualBool(uninitialized_identity.SameRuntimeAs(uninitialized_identity), false, "two uninitialized identities are not the same runtime", tests_run, tests_failed);
}

void TestDelimiterAmbiguityRegression(int &tests_run, int &tests_failed)
{
   SQuantumResult result_a;
   SQuantumResult result_b;
   CQuantumRuntimeIdentity identity_a;
   CQuantumRuntimeIdentity identity_b;

   identity_a.Initialize("Q01|EUR", "A", "USD", result_a);
   identity_b.Initialize("Q01", "A", "EUR|USD", result_b);

   AssertEqualBool(result_a.IsOk(), true, "first delimiter regression identity initializes", tests_run, tests_failed);
   AssertEqualBool(result_b.IsOk(), true, "second delimiter regression identity initializes", tests_run, tests_failed);
   AssertNotEqualLong(identity_a.MagicNumber(), identity_b.MagicNumber(), "field boundaries prevent delimiter ambiguity collision", tests_run, tests_failed);
}

void TestImmutability(int &tests_run, int &tests_failed)
{
   SQuantumResult result;
   CQuantumRuntimeIdentity identity;

   identity.Initialize("Q01", "A", "EURUSD", result);
   const long original_magic = identity.MagicNumber();

   result.Reset();
   AssertEqualBool(identity.Initialize("Q01", "B", "EURUSD", result), false, "reinitialization rejected", tests_run, tests_failed);
   AssertEqualBool(result.HasFailure(), true, "reinitialization explicit failure", tests_run, tests_failed);
   AssertEqualString(identity.InstanceID(), "A", "instance unchanged after rejected mutation", tests_run, tests_failed);
   AssertEqualLong(identity.MagicNumber(), original_magic, "magic unchanged after rejected mutation", tests_run, tests_failed);
}

void OnStart()
{
   int tests_run = 0;
   int tests_failed = 0;

   TestValidInitialization(tests_run, tests_failed);
   TestInvalidInitialization(tests_run, tests_failed);
   TestWhitespaceInitialization(tests_run, tests_failed);
   TestDeterminismAndDistinguishability(tests_run, tests_failed);
   TestRetryAfterFailedInitialization(tests_run, tests_failed);
   TestUninitializedComparisons(tests_run, tests_failed);
   TestDelimiterAmbiguityRegression(tests_run, tests_failed);
   TestImmutability(tests_run, tests_failed);

   if(tests_failed > 0)
   {
      Print("Project Quantum Phase 1.2 runtime identity tests failed: ", tests_failed, "/", tests_run);
      return;
   }
   
   Print("Project Quantum Phase 1.2 runtime identity tests passed: ", tests_run, "/", tests_run);
}
