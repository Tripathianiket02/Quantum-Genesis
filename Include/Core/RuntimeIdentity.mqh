#ifndef __QUANTUM_CORE_RUNTIME_IDENTITY_MQH__
#define __QUANTUM_CORE_RUNTIME_IDENTITY_MQH__

#include "Types.mqh"

//+------------------------------------------------------------------+
//| Project Quantum — Runtime Identity                               |
//| Owner: Platform foundation / Configuration foundation             |
//| Consumers: every instance-scoped component that needs ownership   |
//| Mutability: initialize once, read thereafter                      |
//| Lifetime: one Quantum runtime instance                            |
//+------------------------------------------------------------------+

class CQuantumRuntimeIdentity
{
private:
   string m_symbol;
   string m_strategy_id;
   string m_instance_id;
   long   m_magic_number;
   bool   m_initialized;

   bool IsNonEmpty(const string value)
   {
      return (StringLen(value) > 0);
   }

   uint HashCharacter(const uint hash_value, const ushort character)
   {
      // 32-bit FNV-1a step. Deterministic, explicit, local, and MQL5-friendly.
      ulong next_hash = (ulong)(hash_value ^ (uint)character);
      next_hash = (next_hash * 16777619UL) & 0xFFFFFFFFUL;
      return (uint)next_hash;
   }

   uint HashString(const uint hash_value, const string value)
   {
      uint hash = hash_value;
      const int length = StringLen(value);

      for(int index = 0; index < length; index++)
      {
         hash = HashCharacter(hash, (ushort)StringGetCharacter(value, index));
      }

      return hash;
   }

   long CalculateMagicNumber(const string strategy_id,
                             const string instance_id,
                             const string symbol)
   {
      uint hash = (uint)2166136261UL;
      hash = HashString(hash, strategy_id);
      hash = HashCharacter(hash, (ushort)StringGetCharacter("|", 0));
      hash = HashString(hash, symbol);
      hash = HashCharacter(hash, (ushort)StringGetCharacter("|", 0));
      hash = HashString(hash, instance_id);

      // Keep the value positive and comfortably within signed 32-bit integer range.
      return (long)(100000 + (hash % 900000000U));
   }

   public:
   CQuantumRuntimeIdentity()
   {
      m_symbol = "";
      m_strategy_id = "";
      m_instance_id = "";
      m_magic_number = 0;
      m_initialized = false;
   }

   bool Initialize(const string strategy_id,
                   const string instance_id,
                   const string symbol,
                   SQuantumResult &result)
   {
      if(m_initialized)
      {
         result.SetBlocked(QUANTUM_COMPONENT_PLATFORM,
                           QUANTUM_ERROR_INVALID_STATE,
                           "CQuantumRuntimeIdentity.Initialize",
                           "RuntimeIdentity is already initialized and immutable for this runtime lifetime.",
                           "Create a new runtime identity instance instead of mutating this one.");
         return false;
      }

      if(!IsNonEmpty(strategy_id))
      {
         result.SetError(QUANTUM_COMPONENT_PLATFORM,
                         QUANTUM_ERROR_INVALID_ARGUMENT,
                         "CQuantumRuntimeIdentity.Initialize",
                         "StrategyID is required.",
                         "Provide the configured Quantum strategy identifier during initialization.");
         return false;
      }
      
      if(!IsNonEmpty(instance_id))
      {
         result.SetError(QUANTUM_COMPONENT_PLATFORM,
                         QUANTUM_ERROR_INVALID_ARGUMENT,
                         "CQuantumRuntimeIdentity.Initialize",
                         "InstanceID is required to distinguish multiple instances of the same strategy.",
                         "Provide a configured instance identifier during initialization.");
         return false;
      }

      if(!IsNonEmpty(symbol))
      {
         result.SetError(QUANTUM_COMPONENT_PLATFORM,
                         QUANTUM_ERROR_INVALID_ARGUMENT,
                         "CQuantumRuntimeIdentity.Initialize",
                         "Symbol is required for symbol-scoped runtime binding.",
                         "Pass the bound chart/runtime symbol during initialization.");
         return false;
      }

      const long magic_number = CalculateMagicNumber(strategy_id, instance_id, symbol);
      if(magic_number <= 0)
      {
         result.SetError(QUANTUM_COMPONENT_PLATFORM,
                         QUANTUM_ERROR_VALIDATION_FAILED,
                         "CQuantumRuntimeIdentity.Initialize",
                         "Calculated MagicNumber is invalid.",
                         "Review deterministic magic-number calculation inputs.");
         return false;
      }

      m_strategy_id = strategy_id;
      m_instance_id = instance_id;
      m_symbol = symbol;
      m_magic_number = magic_number;
      m_initialized = true;

      result.SetOk(QUANTUM_COMPONENT_PLATFORM,
                   "CQuantumRuntimeIdentity.Initialize",
                   "RuntimeIdentity initialized.");
      return true;
   }

   bool IsInitialized()
   {
      return m_initialized;
   }

   string Symbol()
   {
      return m_symbol;
   }

   string StrategyID()
   {
      return m_strategy_id;
   }

   string InstanceID()
   {
      return m_instance_id;
   }

   long MagicNumber()
   {
      return m_magic_number;
   }

   bool MatchesOwnership(const string symbol, const long magic_number)
   {
      return (m_initialized && symbol == m_symbol && magic_number == m_magic_number);
   }

   bool SameRuntimeAs(CQuantumRuntimeIdentity &other)
   {
      return (m_initialized && other.IsInitialized() &&
              m_symbol == other.Symbol() &&
              m_strategy_id == other.StrategyID() &&
              m_instance_id == other.InstanceID() &&
              m_magic_number == other.MagicNumber());
   }
};

#endif // __QUANTUM_CORE_RUNTIME_IDENTITY_MQH__