#property script_show_inputs

#include "../Core/Types.mqh"

//+------------------------------------------------------------------+
//| Project Quantum — Phase 1.1 Core Foundation Primitive Checks      |
//| This script verifies deterministic enum mappings and result state. |
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

void TestStatusMappings(int &tests_run, int &tests_failed)
{
   AssertEqualString(QuantumStatusToString(QUANTUM_STATUS_UNKNOWN), "UNKNOWN", "status unknown", tests_run, tests_failed);
   AssertEqualString(QuantumStatusToString(QUANTUM_STATUS_OK), "OK", "status ok", tests_run, tests_failed);
   AssertEqualString(QuantumStatusToString(QUANTUM_STATUS_WARNING), "WARNING", "status warning", tests_run, tests_failed);
   AssertEqualString(QuantumStatusToString(QUANTUM_STATUS_ERROR), "ERROR", "status error", tests_run, tests_failed);
   AssertEqualString(QuantumStatusToString(QUANTUM_STATUS_BLOCKED), "BLOCKED", "status blocked", tests_run, tests_failed);
   AssertEqualString(QuantumStatusToString((ENUM_QUANTUM_STATUS)999), "UNKNOWN", "status invalid fallback", tests_run, tests_failed);
}

void TestComponentMappings(int &tests_run, int &tests_failed)
{
   AssertEqualString(QuantumComponentIdToString(QUANTUM_COMPONENT_CORE), "CORE", "component core", tests_run, tests_failed);
   AssertEqualString(QuantumComponentIdToString(QUANTUM_COMPONENT_PLATFORM), "PLATFORM", "component platform", tests_run, tests_failed);
   AssertEqualString(QuantumComponentIdToString(QUANTUM_COMPONENT_TEST), "TEST", "component test", tests_run, tests_failed);
   AssertEqualString(QuantumComponentIdToString((ENUM_QUANTUM_COMPONENT_ID)999), "UNKNOWN", "component invalid fallback", tests_run, tests_failed);
}

void TestErrorMappings(int &tests_run, int &tests_failed)
{
   AssertEqualString(QuantumErrorCodeToString(QUANTUM_ERROR_NONE), "NONE", "error none", tests_run, tests_failed);
   AssertEqualString(QuantumErrorCodeToString(QUANTUM_ERROR_INVALID_ARGUMENT), "INVALID_ARGUMENT", "error invalid argument", tests_run, tests_failed);
   AssertEqualString(QuantumErrorCodeToString(QUANTUM_ERROR_INTERNAL), "INTERNAL", "error internal", tests_run, tests_failed);
   AssertEqualString(QuantumErrorCodeToString((ENUM_QUANTUM_ERROR_CODE)999), "INTERNAL", "error invalid fallback", tests_run, tests_failed);
}

void TestResultStateTransitions(int &tests_run, int &tests_failed)
{
   SQuantumResult result;
   result.Reset();

   AssertEqualString(QuantumStatusToString(result.Status), "UNKNOWN", "result reset status", tests_run, tests_failed);
   AssertEqualBool(result.IsOk(), false, "result reset is not ok", tests_run, tests_failed);
   AssertEqualBool(result.HasFailure(), false, "result reset has no failure", tests_run, tests_failed);

   result.SetOk(QUANTUM_COMPONENT_CORE, "TestOperation", "ready");
   AssertEqualBool(result.IsOk(), true, "result ok is ok", tests_run, tests_failed);
   AssertEqualBool(result.HasFailure(), false, "result ok has no failure", tests_run, tests_failed);

   result.SetError(QUANTUM_COMPONENT_CORE,
                   QUANTUM_ERROR_VALIDATION_FAILED,
                   "TestOperation",
                   "validation failed",
                   "fix input");
   AssertEqualBool(result.IsOk(), false, "result error is not ok", tests_run, tests_failed);
   AssertEqualBool(result.HasFailure(), true, "result error has failure", tests_run, tests_failed);

   result.SetBlocked(QUANTUM_COMPONENT_CORE,
                     QUANTUM_ERROR_OPERATION_BLOCKED,
                     "TestOperation",
                     "blocked",
                     "wait for dependency");
   AssertEqualBool(result.HasFailure(), true, "result blocked has failure", tests_run, tests_failed);
}

void OnStart()
{
   int tests_run = 0;
   int tests_failed = 0;

   TestStatusMappings(tests_run, tests_failed);
   TestComponentMappings(tests_run, tests_failed);
   TestErrorMappings(tests_run, tests_failed);
   TestResultStateTransitions(tests_run, tests_failed);

   if(tests_failed > 0)
   {
      Print("Project Quantum Phase 1.1 core primitive tests failed: ", tests_failed, "/", tests_run);
      return;
   }

   Print("Project Quantum Phase 1.1 core primitive tests passed: ", tests_run, "/", tests_run);
}
