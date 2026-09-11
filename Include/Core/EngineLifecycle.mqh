#ifndef __QUANTUM_CORE_ENGINE_LIFECYCLE_MQH__
#define __QUANTUM_CORE_ENGINE_LIFECYCLE_MQH__

#include "RuntimeIdentity.mqh"

//+------------------------------------------------------------------+
//| Project Quantum — Engine Lifecycle                               |
//| Owner: Core Infrastructure                                       |
//| Consumers: future instance-scoped Quantum engines                |
//| Mutability: controlled state transitions only                    |
//| Lifetime: one engine instance                                    |
//+------------------------------------------------------------------+

// The minimal common engine lifecycle. Stopped is terminal for a
// lifecycle instance; a new engine instance is required to run again.
enum ENUM_QUANTUM_ENGINE_LIFECYCLE_STATE
{
   QUANTUM_ENGINE_STATE_CREATED = 0,
   QUANTUM_ENGINE_STATE_INITIALIZED = 1,
   QUANTUM_ENGINE_STATE_RUNNING = 2,
   QUANTUM_ENGINE_STATE_STOPPED = 3
};

string QuantumEngineLifecycleStateToString(const ENUM_QUANTUM_ENGINE_LIFECYCLE_STATE state)
{
   switch(state)
   {
      case QUANTUM_ENGINE_STATE_CREATED:     return "CREATED";
      case QUANTUM_ENGINE_STATE_INITIALIZED: return "INITIALIZED";
      case QUANTUM_ENGINE_STATE_RUNNING:     return "RUNNING";
      case QUANTUM_ENGINE_STATE_STOPPED:     return "STOPPED";
   }

   return "UNKNOWN";
}

class CQuantumEngineLifecycle
{
private:
   ENUM_QUANTUM_ENGINE_LIFECYCLE_STATE m_state;

public:
   CQuantumEngineLifecycle()
   {
      m_state = QUANTUM_ENGINE_STATE_CREATED;
   }

   bool Initialize(const CQuantumRuntimeIdentity &runtime_identity,
                   SQuantumResult &result)
   {
      if(m_state != QUANTUM_ENGINE_STATE_CREATED)
      {
         result.SetBlocked(QUANTUM_COMPONENT_ENGINE,
                           QUANTUM_ERROR_INVALID_STATE,
                           "CQuantumEngineLifecycle.Initialize",
                           "Engine lifecycle can only be initialized from the Created state.",
                           "Create a new engine instance instead of reinitializing or restarting this one.");
         return false;
      }

      if(!runtime_identity.IsInitialized())
      {
         result.SetError(QUANTUM_COMPONENT_ENGINE,
                         QUANTUM_ERROR_NOT_INITIALIZED,
                         "CQuantumEngineLifecycle.Initialize",
                         "RuntimeIdentity must be initialized before an engine lifecycle can initialize.",
                         "Initialize the owning RuntimeIdentity first, then initialize the engine lifecycle.");
         return false;
      }

      m_state = QUANTUM_ENGINE_STATE_INITIALIZED;
      result.SetOk(QUANTUM_COMPONENT_ENGINE,
                   "CQuantumEngineLifecycle.Initialize",
                   "Engine lifecycle initialized for the supplied runtime identity.");
      return true;
   }

   bool Start(SQuantumResult &result)
   {
      if(m_state == QUANTUM_ENGINE_STATE_CREATED)
      {
         result.SetError(QUANTUM_COMPONENT_ENGINE,
                         QUANTUM_ERROR_NOT_INITIALIZED,
                         "CQuantumEngineLifecycle.Start",
                         "Engine lifecycle must be initialized before it can start.",
                         "Initialize the engine lifecycle with an initialized RuntimeIdentity first.");
         return false;
      }

      if(m_state != QUANTUM_ENGINE_STATE_INITIALIZED)
      {
         result.SetBlocked(QUANTUM_COMPONENT_ENGINE,
                           QUANTUM_ERROR_INVALID_STATE,
                           "CQuantumEngineLifecycle.Start",
                           "Engine lifecycle can only start from the Initialized state.",
                           "Do not start an already running or stopped engine; create a new instance after stop.");
         return false;
      }

      m_state = QUANTUM_ENGINE_STATE_RUNNING;
      result.SetOk(QUANTUM_COMPONENT_ENGINE,
                   "CQuantumEngineLifecycle.Start",
                   "Engine lifecycle started.");
      return true;
   }

   bool Stop(SQuantumResult &result)
   {
      if(m_state != QUANTUM_ENGINE_STATE_RUNNING)
      {
         result.SetBlocked(QUANTUM_COMPONENT_ENGINE,
                           QUANTUM_ERROR_INVALID_STATE,
                           "CQuantumEngineLifecycle.Stop",
                           "Engine lifecycle can only stop from the Running state.",
                           "Start an initialized engine before stopping it; create a new instance after stop.");
         return false;
      }

      m_state = QUANTUM_ENGINE_STATE_STOPPED;
      result.SetOk(QUANTUM_COMPONENT_ENGINE,
                   "CQuantumEngineLifecycle.Stop",
                   "Engine lifecycle stopped. This lifecycle instance is terminal.");
      return true;
   }

   ENUM_QUANTUM_ENGINE_LIFECYCLE_STATE State() const
   {
      return m_state;
   }

   bool IsInitialized() const
   {
      return (m_state == QUANTUM_ENGINE_STATE_INITIALIZED ||
              m_state == QUANTUM_ENGINE_STATE_RUNNING ||
              m_state == QUANTUM_ENGINE_STATE_STOPPED);
   }

   bool IsRunning() const
   {
      return (m_state == QUANTUM_ENGINE_STATE_RUNNING);
   }
};

#endif // __QUANTUM_CORE_ENGINE_LIFECYCLE_MQH__
