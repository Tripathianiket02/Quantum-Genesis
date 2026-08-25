#ifndef __QUANTUM_CORE_TYPES_MQH__
#define __QUANTUM_CORE_TYPES_MQH__

//+------------------------------------------------------------------+
//| Project Quantum — Core Foundation Types                          |
//| Owner: Core Infrastructure                                       |
//| Consumers: all later foundation components and engines            |
//| Mutability: values are copied by callers; no shared mutable state |
//| Lifetime: per value instance                                      |
//+------------------------------------------------------------------+

// Canonical operation status values shared by foundation components.
enum ENUM_QUANTUM_STATUS
{
   QUANTUM_STATUS_UNKNOWN = 0,
   QUANTUM_STATUS_OK = 1,
   QUANTUM_STATUS_WARNING = 2,
   QUANTUM_STATUS_ERROR = 3,
   QUANTUM_STATUS_BLOCKED = 4
};

// Canonical component identifiers used in result/error records.
enum ENUM_QUANTUM_COMPONENT_ID
{
   QUANTUM_COMPONENT_UNKNOWN = 0,
   QUANTUM_COMPONENT_CORE = 1,
   QUANTUM_COMPONENT_PLATFORM = 2,
   QUANTUM_COMPONENT_CONFIGURATION = 3,
   QUANTUM_COMPONENT_LOGGING = 4,
   QUANTUM_COMPONENT_EVENT_SYSTEM = 5,
   QUANTUM_COMPONENT_KERNEL = 6,
   QUANTUM_COMPONENT_ENGINE = 7,
   QUANTUM_COMPONENT_TEST = 8
};

// Minimal error taxonomy for non-silent, contextual recoverable failures.
enum ENUM_QUANTUM_ERROR_CODE
{
   QUANTUM_ERROR_NONE = 0,
   QUANTUM_ERROR_INVALID_ARGUMENT = 1,
   QUANTUM_ERROR_INVALID_STATE = 2,
   QUANTUM_ERROR_NOT_INITIALIZED = 3,
   QUANTUM_ERROR_VALIDATION_FAILED = 4,
   QUANTUM_ERROR_DEPENDENCY_UNAVAILABLE = 5,
   QUANTUM_ERROR_OPERATION_BLOCKED = 6,
   QUANTUM_ERROR_INTERNAL = 7
};

// Shared result object for foundation operations that need explicit status,
// component ownership, operation context, and recovery guidance.
struct SQuantumResult
{
   ENUM_QUANTUM_STATUS       Status;
   ENUM_QUANTUM_ERROR_CODE   ErrorCode;
   ENUM_QUANTUM_COMPONENT_ID Component;
   string                    Operation;
   string                    Message;
   string                    Recovery;

   void Reset()
   {
      Status = QUANTUM_STATUS_UNKNOWN;
      ErrorCode = QUANTUM_ERROR_NONE;
      Component = QUANTUM_COMPONENT_UNKNOWN;
      Operation = "";
      Message = "";
      Recovery = "";
   }

   void SetOk(const ENUM_QUANTUM_COMPONENT_ID component,
              const string operation,
              const string message = "")
   {
      Status = QUANTUM_STATUS_OK;
      ErrorCode = QUANTUM_ERROR_NONE;
      Component = component;
      Operation = operation;
      Message = message;
      Recovery = "";
   }

   void SetWarning(const ENUM_QUANTUM_COMPONENT_ID component,
                   const ENUM_QUANTUM_ERROR_CODE error_code,
                   const string operation,
                   const string message,
                   const string recovery)
   {
      Status = QUANTUM_STATUS_WARNING;
      ErrorCode = error_code;
      Component = component;
      Operation = operation;
      Message = message;
      Recovery = recovery;
   }

   void SetError(const ENUM_QUANTUM_COMPONENT_ID component,
                 const ENUM_QUANTUM_ERROR_CODE error_code,
                 const string operation,
                 const string message,
                 const string recovery)
   {
      Status = QUANTUM_STATUS_ERROR;
      ErrorCode = error_code;
      Component = component;
      Operation = operation;
      Message = message;
      Recovery = recovery;
   }

   void SetBlocked(const ENUM_QUANTUM_COMPONENT_ID component,
                   const ENUM_QUANTUM_ERROR_CODE error_code,
                   const string operation,
                   const string message,
                   const string recovery)
   {
      Status = QUANTUM_STATUS_BLOCKED;
      ErrorCode = error_code;
      Component = component;
      Operation = operation;
      Message = message;
      Recovery = recovery;
   }

   bool IsOk() const
   {
      return (Status == QUANTUM_STATUS_OK && ErrorCode == QUANTUM_ERROR_NONE);
   }

   bool HasFailure() const
   {
      return (Status == QUANTUM_STATUS_ERROR || Status == QUANTUM_STATUS_BLOCKED);
   }
};

string QuantumStatusToString(const ENUM_QUANTUM_STATUS status)
{
   switch(status)
   {
      case QUANTUM_STATUS_UNKNOWN: return "UNKNOWN";
      case QUANTUM_STATUS_OK:      return "OK";
      case QUANTUM_STATUS_WARNING: return "WARNING";
      case QUANTUM_STATUS_ERROR:   return "ERROR";
      case QUANTUM_STATUS_BLOCKED: return "BLOCKED";
   }

   return "UNKNOWN";
}

string QuantumComponentIdToString(const ENUM_QUANTUM_COMPONENT_ID component)
{
   switch(component)
   {
      case QUANTUM_COMPONENT_UNKNOWN:       return "UNKNOWN";
      case QUANTUM_COMPONENT_CORE:          return "CORE";
      case QUANTUM_COMPONENT_PLATFORM:      return "PLATFORM";
      case QUANTUM_COMPONENT_CONFIGURATION: return "CONFIGURATION";
      case QUANTUM_COMPONENT_LOGGING:       return "LOGGING";
      case QUANTUM_COMPONENT_EVENT_SYSTEM:  return "EVENT_SYSTEM";
      case QUANTUM_COMPONENT_KERNEL:        return "KERNEL";
      case QUANTUM_COMPONENT_ENGINE:        return "ENGINE";
      case QUANTUM_COMPONENT_TEST:          return "TEST";
   }

   return "UNKNOWN";
}

string QuantumErrorCodeToString(const ENUM_QUANTUM_ERROR_CODE error_code)
{
   switch(error_code)
   {
      case QUANTUM_ERROR_NONE:                   return "NONE";
      case QUANTUM_ERROR_INVALID_ARGUMENT:       return "INVALID_ARGUMENT";
      case QUANTUM_ERROR_INVALID_STATE:          return "INVALID_STATE";
      case QUANTUM_ERROR_NOT_INITIALIZED:        return "NOT_INITIALIZED";
      case QUANTUM_ERROR_VALIDATION_FAILED:      return "VALIDATION_FAILED";
      case QUANTUM_ERROR_DEPENDENCY_UNAVAILABLE: return "DEPENDENCY_UNAVAILABLE";
      case QUANTUM_ERROR_OPERATION_BLOCKED:      return "OPERATION_BLOCKED";
      case QUANTUM_ERROR_INTERNAL:               return "INTERNAL";
   }

   return "INTERNAL";
}

#endif // __QUANTUM_CORE_TYPES_MQH__
