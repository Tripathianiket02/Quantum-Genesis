#ifndef __QUANTUM_CORE_CONFIG_MQH__
#define __QUANTUM_CORE_CONFIG_MQH__

#include "Types.mqh"

//+------------------------------------------------------------------+
//| Project Quantum — Configuration (P1.5)                           |
//| Owner: Configuration Engine                                       |
//| Consumers: Platform Layer (RuntimeIdentity/MarketContext inputs), |
//|            and, later, any engine reading centralized parameters  |
//| Mutability: initialize once — construction is publication. No     |
//|             public method can change state after a successful    |
//|             Initialize() call; there is no setter of any kind.   |
//| Lifetime: one Quantum runtime instance                            |
//+------------------------------------------------------------------+
//
// CQuantumConfig owns Instance Configuration (ADR-001 Section 20): the
// smallest set of externally adjustable parameters that already have a
// concrete consumer elsewhere in this repository today. No risk,
// execution, scoring, or analysis parameters are defined here: no
// accepted repository document assigns this foundation stage a schema
// for them, and inventing one now would be scope creep (recorded as
// NOTE-003 in IMPLEMENTATION_PROGRESS.md for CTO review).
//
// Parameters (PROJECT_GOVERNANCE.md "Configuration Policy": each
// parameter is documented with description, default, valid range, and
// reason for existence):
//
//   Symbol
//     Description : the trading symbol this Quantum instance is configured to bind to.
//     Default     : "" (none; must be explicitly configured).
//     Valid range : any non-empty string with no leading/trailing whitespace.
//     Reason      : ADR-001 Section 20 lists "Symbol-specific parameters" as Instance
//                   Configuration. The Platform Layer reads this configured value once,
//                   at OnInit, to call CQuantumRuntimeIdentity.Initialize() (Contracts/
//                   Shared Data Objects.md lists RuntimeIdentity's owner as "Platform
//                   Layer / Configuration Engine"). Config holds this only as
//                   pre-initialization input: it does not compute a MagicNumber, expose
//                   any ownership-matching method, or get consulted for ownership once
//                   RuntimeIdentity is initialized. RuntimeIdentity remains the sole
//                   authoritative identity owner (ADR-001) — Config never becomes a
//                   second identity authority.
//
//   StrategyID
//     Description : identifies which strategy/codebase this instance runs.
//     Default     : "" (none; must be explicitly configured).
//     Valid range : any non-empty string with no leading/trailing whitespace.
//     Reason      : ADR-001 Section 20 lists "Strategy parameters" as Instance
//                   Configuration; also a direct RuntimeIdentity.Initialize() input,
//                   under the same pre-initialization-input rule described above.
//
//   InstanceID
//     Description : distinguishes this instance from any other instance of the same
//                   StrategyID (ADR-001 Section 6.1).
//     Default     : "" (none; must be explicitly configured).
//     Valid range : any non-empty string with no leading/trailing whitespace.
//     Reason      : a direct RuntimeIdentity.Initialize() input, under the same
//                   pre-initialization-input rule described above.
//
//   WorkingTimeframe
//     Description : the working timeframe this instance evaluates each cycle on.
//     Default     : PERIOD_CURRENT — treated as "not configured", not a valid captured value.
//     Valid range : any ENUM_TIMEFRAMES value except PERIOD_CURRENT.
//     Reason      : ADR-001 Section 20 lists "Timeframe settings" as Instance
//                   Configuration. CQuantumMarketContext.Initialize() (P1.4) already
//                   requires an explicit ENUM_TIMEFRAMES with no other designated
//                   source; Configuration is the natural owner of that configured value.
//
// Config performs no market-data or terminal acquisition of any kind, and depends
// only on Types.mqh, keeping it low in the dependency hierarchy and independently
// testable.
class CQuantumConfig
{
private:
   bool            m_initialized;
   string          m_symbol;
   string          m_strategy_id;
   string          m_instance_id;
   ENUM_TIMEFRAMES m_working_timeframe;

   bool IsNonEmpty(const string value) const
   {
      return (StringLen(value) > 0);
   }

   bool HasLeadingOrTrailingWhitespace(const string value) const
   {
      string trimmed_value = value;
      StringTrimLeft(trimmed_value);
      StringTrimRight(trimmed_value);
      return (trimmed_value != value);
   }

public:
   CQuantumConfig()
   {
      m_initialized = false;
      m_symbol = "";
      m_strategy_id = "";
      m_instance_id = "";
      m_working_timeframe = PERIOD_CURRENT;
   }

   bool Initialize(const string symbol,
                   const string strategy_id,
                   const string instance_id,
                   const ENUM_TIMEFRAMES working_timeframe,
                   SQuantumResult &result)
   {
      if(m_initialized)
      {
         result.SetBlocked(QUANTUM_COMPONENT_CONFIGURATION,
                           QUANTUM_ERROR_INVALID_STATE,
                           "CQuantumConfig.Initialize",
                           "Configuration is already initialized and immutable once published.",
                           "Create a new Config instance instead of mutating this one.");
         return false;
      }

      if(!IsNonEmpty(symbol))
      {
         result.SetError(QUANTUM_COMPONENT_CONFIGURATION,
                         QUANTUM_ERROR_INVALID_ARGUMENT,
                         "CQuantumConfig.Initialize",
                         "Symbol is required.",
                         "Provide the configured instance symbol before initialization.");
         return false;
      }

      if(HasLeadingOrTrailingWhitespace(symbol))
      {
         result.SetError(QUANTUM_COMPONENT_CONFIGURATION,
                         QUANTUM_ERROR_INVALID_ARGUMENT,
                         "CQuantumConfig.Initialize",
                         "Symbol must not contain leading or trailing whitespace.",
                         "Remove leading or trailing whitespace from Symbol before initialization.");
         return false;
      }

      if(!IsNonEmpty(strategy_id))
      {
         result.SetError(QUANTUM_COMPONENT_CONFIGURATION,
                         QUANTUM_ERROR_INVALID_ARGUMENT,
                         "CQuantumConfig.Initialize",
                         "StrategyID is required.",
                         "Provide the configured strategy identifier before initialization.");
         return false;
      }

      if(HasLeadingOrTrailingWhitespace(strategy_id))
      {
         result.SetError(QUANTUM_COMPONENT_CONFIGURATION,
                         QUANTUM_ERROR_INVALID_ARGUMENT,
                         "CQuantumConfig.Initialize",
                         "StrategyID must not contain leading or trailing whitespace.",
                         "Remove leading or trailing whitespace from StrategyID before initialization.");
         return false;
      }

      if(!IsNonEmpty(instance_id))
      {
         result.SetError(QUANTUM_COMPONENT_CONFIGURATION,
                         QUANTUM_ERROR_INVALID_ARGUMENT,
                         "CQuantumConfig.Initialize",
                         "InstanceID is required.",
                         "Provide a configured instance identifier before initialization.");
         return false;
      }

      if(HasLeadingOrTrailingWhitespace(instance_id))
      {
         result.SetError(QUANTUM_COMPONENT_CONFIGURATION,
                         QUANTUM_ERROR_INVALID_ARGUMENT,
                         "CQuantumConfig.Initialize",
                         "InstanceID must not contain leading or trailing whitespace.",
                         "Remove leading or trailing whitespace from InstanceID before initialization.");
         return false;
      }

      if(working_timeframe == PERIOD_CURRENT)
      {
         result.SetError(QUANTUM_COMPONENT_CONFIGURATION,
                         QUANTUM_ERROR_INVALID_ARGUMENT,
                         "CQuantumConfig.Initialize",
                         "WorkingTimeframe must be an explicit period; PERIOD_CURRENT is a relative placeholder, not a configured value.",
                         "Configure a concrete ENUM_TIMEFRAMES value before initialization.");
         return false;
      }

      m_symbol = symbol;
      m_strategy_id = strategy_id;
      m_instance_id = instance_id;
      m_working_timeframe = working_timeframe;
      m_initialized = true;

      result.SetOk(QUANTUM_COMPONENT_CONFIGURATION,
                   "CQuantumConfig.Initialize",
                   "Configuration initialized and published.");
      return true;
   }

   bool IsInitialized() const
   {
      return m_initialized;
   }

   string Symbol() const
   {
      return m_symbol;
   }

   string StrategyID() const
   {
      return m_strategy_id;
   }

   string InstanceID() const
   {
      return m_instance_id;
   }

   ENUM_TIMEFRAMES WorkingTimeframe() const
   {
      return m_working_timeframe;
   }
};

#endif // __QUANTUM_CORE_CONFIG_MQH__