#ifndef __QUANTUM_CORE_MARKET_CONTEXT_MQH__
#define __QUANTUM_CORE_MARKET_CONTEXT_MQH__

#include "RuntimeIdentity.mqh"

//+------------------------------------------------------------------+
//| Project Quantum — Market Context / Snapshot (P1.4)               |
//| Owner: Platform Layer                                            |
//| Consumers: every Analysis Layer engine within one evaluation      |
//|            cycle (SYSTEM_ARCHITECTURE.md Section 11, "Snapshots";  |
//|            Contracts/Shared Data Objects.md, "MarketContext")      |
//| Mutability: initialize once — construction is publication. No     |
//|             public method can change state after a successful    |
//|             Initialize() call; there is no setter of any kind.   |
//| Lifetime: one evaluation cycle                                    |
//+------------------------------------------------------------------+
//
// MarketContext carries already-captured Platform Layer state for one
// cycle: the bound runtime symbol (read from RuntimeIdentity, never a
// second independent identity authority), the working timeframe, a
// cycle/snapshot identifier, a captured price tick, and captured
// account state (balance, equity).
//
// MarketContext performs no market-data acquisition itself. It never
// calls SymbolInfoTick, CopyRates, AccountInfoDouble, PositionSelect,
// OrderSelect, or any other terminal API internally — every value is
// supplied explicitly by the caller, already captured, at
// construction time. This keeps the snapshot representation
// deterministic and independently testable, and guarantees that no
// consumer can observe changing terminal state through it (P1.4
// architectural scope; SYSTEM_ARCHITECTURE.md Section 4.1).
//
// P1.4 is not an analysis engine: it carries data, it does not
// interpret it. It does not detect structure, liquidity, zones,
// regime, or session context, and it makes no trading decisions.
//

class CQuantumMarketContext
{
private:
   bool            m_initialized;
   ulong           m_cycle_id;
   string          m_symbol;
   ENUM_TIMEFRAMES m_timeframe;
   MqlTick         m_tick;
   double          m_account_balance;
   double          m_account_equity;

   bool IsValidTick(const MqlTick &tick) const
   {
      // A real captured tick has a positive, non-crossed quote and a
      // populated timestamp. A zeroed/default struct (an uncaptured
      // tick passed in by mistake) is rejected here rather than
      // silently accepted as valid market state.
      return (tick.bid > 0.0 && tick.ask > 0.0 && tick.ask >= tick.bid && tick.time > 0);
   }

public:
   CQuantumMarketContext()
   {
      m_initialized = false;
      m_cycle_id = 0;
      m_symbol = "";
      m_timeframe = PERIOD_CURRENT;
      m_account_balance = 0.0;
      m_account_equity = 0.0;
      // m_tick is a native MQL5 struct with no constructor of its own;
      // MQL5 zero-initializes struct members on declaration, so no
      // explicit field-by-field reset is required here.
   }

   bool Initialize(const CQuantumRuntimeIdentity &runtime_identity,
                   const ENUM_TIMEFRAMES timeframe,
                   const ulong cycle_id,
                   const MqlTick &tick,
                   const double account_balance,
                   const double account_equity,
                   SQuantumResult &result)
   {
      if(m_initialized)
      {
         result.SetBlocked(QUANTUM_COMPONENT_PLATFORM,
                           QUANTUM_ERROR_INVALID_STATE,
                           "CQuantumMarketContext.Initialize",
                           "MarketContext is already initialized and immutable once published for its cycle.",
                           "Create a new MarketContext instance for the next cycle instead of mutating this one.");
         return false;
      }

      if(!runtime_identity.IsInitialized())
      {
         result.SetError(QUANTUM_COMPONENT_PLATFORM,
                         QUANTUM_ERROR_NOT_INITIALIZED,
                         "CQuantumMarketContext.Initialize",
                         "RuntimeIdentity must be initialized before a MarketContext snapshot can be constructed.",
                         "Initialize the owning RuntimeIdentity first, then construct the MarketContext snapshot.");
         return false;
      }

      if(timeframe == PERIOD_CURRENT)
      {
         result.SetError(QUANTUM_COMPONENT_PLATFORM,
                         QUANTUM_ERROR_INVALID_ARGUMENT,
                         "CQuantumMarketContext.Initialize",
                         "Timeframe must be an explicit, captured period; PERIOD_CURRENT is a relative placeholder, not a captured value.",
                         "Resolve the working timeframe to a concrete ENUM_TIMEFRAMES value before capturing the snapshot.");
         return false;
      }

      if(cycle_id == 0)
      {
         result.SetError(QUANTUM_COMPONENT_PLATFORM,
                         QUANTUM_ERROR_INVALID_ARGUMENT,
                         "CQuantumMarketContext.Initialize",
                         "Cycle/snapshot identifier must be a non-zero, explicitly assigned value.",
                         "Assign a deterministic, non-zero cycle identifier before constructing the snapshot.");
         return false;
      }

      if(!IsValidTick(tick))
      {
         result.SetError(QUANTUM_COMPONENT_PLATFORM,
                         QUANTUM_ERROR_VALIDATION_FAILED,
                         "CQuantumMarketContext.Initialize",
                         "Captured price state is invalid: bid, ask, and time must come from a real captured tick.",
                         "Capture a real MqlTick (for example via SymbolInfoTick) before constructing the snapshot.");
         return false;
      }

      m_symbol = runtime_identity.Symbol();
      m_timeframe = timeframe;
      m_cycle_id = cycle_id;
      m_tick = tick;
      m_account_balance = account_balance;
      m_account_equity = account_equity;
      m_initialized = true;

      result.SetOk(QUANTUM_COMPONENT_PLATFORM,
                   "CQuantumMarketContext.Initialize",
                   "MarketContext snapshot constructed and published for its cycle.");
      return true;
   }

   bool IsInitialized() const
   {
      return m_initialized;
   }

   ulong CycleId() const
   {
      return m_cycle_id;
   }

   string Symbol() const
   {
      return m_symbol;
   }

   ENUM_TIMEFRAMES Timeframe() const
   {
      return m_timeframe;
   }

   // Returns a copy of the captured tick. The caller receives a value,
   // never a reference into this object's internal state, so nothing
   // the caller does to the returned MqlTick can mutate this snapshot.
   MqlTick Tick() const
   {
      return m_tick;
   }

   double AccountBalance() const
   {
      return m_account_balance;
   }

   double AccountEquity() const
   {
      return m_account_equity;
   }
};

#endif // __QUANTUM_CORE_MARKET_CONTEXT_MQH__