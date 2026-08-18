# ADR-001 — Symbol-Scoped Runtime Architecture

**Project:** Project Quantum
**ADR ID:** ADR-001
**Title:** Symbol-Scoped Runtime Architecture
**Status:** Accepted
**Proposed:** 2026-08-08
**Amended:** 2026-08-12 (Reconciliation Pass — see Section 37)
**Decision Authority:** Project Owner
**Architecture Authority:** Chief System Architect
**Technical Review:** Principal Software Engineer
**Implementation:** Implementation Engineer

---

# 1. Decision Summary

Project Quantum shall operate as a **symbol-scoped runtime architecture**.

Each running Quantum Expert Advisor instance shall be bound to **exactly one trading symbol**.

The fundamental runtime unit of Project Quantum is therefore:

> **One Quantum EA Instance = One Trading Symbol = One Independent Runtime**

Multiple symbols shall be supported by running multiple independent Quantum EA instances rather than by creating one centralized multi-symbol Quantum runtime. Multiple independently identified Quantum instances may also operate on the same symbol (Section 6.1).

For example:

```text
MT5 Terminal
│
├── EURUSD Chart
│   └── Quantum Instance
│
├── GBPUSD Chart
│   └── Quantum Instance
│
├── USDJPY Chart
│   └── Quantum Instance
│
└── XAUUSD Chart
    └── Quantum Instance
```

Each instance owns its own runtime state, market analysis, decision state, risk state, execution state, position lifecycle state, statistics, and observability state.

No inter-instance communication is required for normal Quantum operation.

---

# 2. Context

## 2.1 Original Architectural Ambiguity

The Project Quantum architecture defines the platform as a modular quantitative trading system capable of operating across multiple instruments.

However, the architecture did not previously make one important runtime decision explicit:

> Does a Quantum engine operate globally across multiple symbols, or does each running EA instance operate on one symbol independently?

This ambiguity becomes particularly important for:

* Market Data
* Market Regime
* Market Structure
* Liquidity
* Institutional Models
* Trade Quality
* Risk
* Execution
* Position Lifecycle
* Statistics
* Dashboard
* Configuration

Without a formal decision, different implementations could interpret the architecture differently.

One implementation could create:

```text
Global Quantum Kernel
        │
        ├── EURUSD
        ├── GBPUSD
        ├── USDJPY
        └── XAUUSD
```

while another could create:

```text
EURUSD → Quantum Kernel

GBPUSD → Quantum Kernel

USDJPY → Quantum Kernel

XAUUSD → Quantum Kernel
```

Both interpretations could appear reasonable from the existing documentation. `SYSTEM_ARCHITECTURE.md` Section 2's original scope statement — "on one or more instruments" — is the specific sentence that made both readings defensible; it did not specify per-instance binding.

This ADR resolves that ambiguity.

---

# 3. Problem Statement

Project Quantum is being developed as a practical MQL5 platform by a single developer.

The platform should be:

* Deterministic
* Modular
* Explainable
* Maintainable
* AI-reviewable
* Performance-conscious
* Simple enough to operate on a single workstation

A centralized multi-symbol runtime would introduce additional complexity into:

* State ownership
* Market data management
* Symbol routing
* Event handling
* Risk coordination
* Position ownership
* Execution
* Testing
* Debugging
* AI-assisted development

The platform therefore requires a runtime model that provides strong isolation while still allowing the same Quantum codebase to be attached to many instruments.

---

# 4. Decision

Project Quantum adopts the following runtime model:

> **Every running Quantum EA instance is permanently bound to one trading symbol.**

The symbol is established by the chart/EA context in which the Quantum instance runs.

Each instance shall independently perform:

```text
Market Data
      ↓
Market Regime
      ↓
Market Structure
      ↓
Liquidity
      ↓
Institutional Models
      ↓
Trade Quality
      ↓
Risk
      ↓
Execution
      ↓
Position Lifecycle
      ↓
Statistics
```

The same architecture and codebase may be instantiated repeatedly for different symbols.

---

# 5. Runtime Instance Definition

A Quantum runtime instance is defined as:

```text
Quantum Instance
│
├── Instance Identity
│
├── Symbol
│
├── Configuration
│
├── Runtime State
│
├── Market Snapshot
│
├── Analysis Engines
│
├── Decision State
│
├── Risk State
│
├── Execution State
│
├── Position Lifecycle State
│
├── Statistics
│
└── Observability
```

The instance owns all runtime state associated with its symbol.

---

# 6. Symbol Binding

Every Quantum instance shall have one immutable primary symbol during its runtime lifetime.

Conceptually:

```text
QuantumInstance.Symbol = ChartSymbol
```

The instance shall not dynamically change its primary symbol during execution.

If the user wants Quantum to operate on another symbol, a separate Quantum instance shall be attached to that symbol.

This constraint runs in one direction only: it fixes one instance to one symbol, but it does not restrict how many instances may share a symbol. See Section 6.1.

## 6.1 Multiple Instances on the Same Symbol

Do **not** interpret Section 6 as "one Quantum instance per symbol per account." That is not the intended restriction.

Multiple independently identified Quantum instances may operate on the same symbol simultaneously. For example:

```text
EURUSD
│
├── Quantum Instance A
│   └── Magic = 210001
│
└── Quantum Instance B
    └── Magic = 210002
```

This is required to support, at minimum:

* Parameter variants
* Research variants
* Strategy versions
* A/B testing
* Different risk profiles on the same instrument

**Consequence for runtime identity.** Because two instances may share a symbol, `Symbol` alone is not sufficient runtime identity. Every instance's identity must be resolvable through the combination defined in Section 18: Strategy ID, Instance ID, Symbol, and Magic Number. Section 18 is amended accordingly.

---

# 7. Independent Instance Model

Each symbol operates as an independent Quantum runtime.

For example:

```text
EURUSD
│
└── Quantum Instance A
    ├── Market Data
    ├── Structure
    ├── Liquidity
    ├── Models
    ├── Risk
    ├── Execution
    └── Statistics


GBPUSD
│
└── Quantum Instance B
    ├── Market Data
    ├── Structure
    ├── Liquidity
    ├── Models
    ├── Risk
    ├── Execution
    └── Statistics


XAUUSD
│
└── Quantum Instance C
    ├── Market Data
    ├── Structure
    ├── Liquidity
    ├── Models
    ├── Risk
    ├── Execution
    └── Statistics
```

The instances share **code and architecture**, but do not share runtime state.

---

# 8. Shared Code vs Shared State

A critical distinction shall be maintained:

> **Shared implementation does not imply shared runtime state.**

Multiple Quantum instances may execute the same compiled code.

However:

```text
EURUSD State ≠ GBPUSD State
```

and:

```text
GBPUSD State ≠ XAUUSD State
```

No analysis engine may implicitly depend upon the runtime state of another symbol instance.

---

# 9. State Ownership

Each runtime state object shall have exactly one owner.

For example:

```text
EURUSD Instance
    │
    ├── EURUSD Market State
    ├── EURUSD Structure State
    ├── EURUSD Liquidity State
    ├── EURUSD Decision State
    ├── EURUSD Risk State
    └── EURUSD Position State
```

The EURUSD instance is responsible for the lifecycle of these objects.

Another instance shall not directly modify them.

---

# 10. Market Data Scope

Market Data within the core Quantum runtime shall be **symbol-scoped**.

A Quantum instance shall primarily consume market data belonging to its own symbol.

For example:

```text
EURUSD Quantum
    ↓
EURUSD Market Data
```

It shall not require:

```text
EURUSD Quantum
    ↓
GBPUSD Market Data
    ↓
XAUUSD Market Data
    ↓
USDJPY Market Data
```

for normal operation.

---

# 11. Analysis Scope

All core analysis engines shall operate on the primary symbol of their owning runtime instance.

This includes:

* Market Regime
* Market Structure
* Liquidity
* Institutional Models
* Trade Quality
* Signal generation

For example:

```text
XAUUSD Quantum
       ↓
XAUUSD Structure
       ↓
XAUUSD Liquidity
       ↓
XAUUSD Institutional Context
       ↓
XAUUSD Trade Quality
```

The analysis engine does not need to know about other Quantum instances.

---

# 12. Cross-Symbol Analysis

Cross-symbol analysis is **not part of the core Quantum runtime contract**.

This means that a Quantum instance shall not require another symbol's runtime state to produce its normal trading decision.

Cross-symbol information may be introduced in a future architectural extension if a demonstrated research requirement justifies it.

Such an extension shall require a separate ADR.

---

# 13. Risk Scope

The Risk Engine shall operate primarily within the scope of its owning Quantum instance.

The core Risk Engine shall be responsible for determining whether the current symbol's proposed trade satisfies the configured risk constraints.

Examples include:

* Risk per trade
* Stop-loss based position sizing
* Maximum position size
* Symbol-level exposure
* Margin constraints
* Maximum concurrent positions
* Instance-level trading limits
* Configured loss limits

The Risk Engine shall not implicitly assume responsibility for portfolio-wide cross-symbol coordination.

---

# 14. Portfolio-Level Risk

Portfolio-wide risk management is explicitly outside the scope of the core symbol-scoped runtime.

Therefore, the following are **not guaranteed by Quantum V1**:

* Total exposure across all Quantum instances
* Cross-symbol correlation exposure
* Aggregate currency exposure
* Global strategy exposure
* Centralized portfolio allocation
* Cross-instance position netting

For example:

```text
EURUSD Quantum
    Risk = 0.50%

GBPUSD Quantum
    Risk = 0.50%

XAUUSD Quantum
    Risk = 0.50%
```

Each instance may independently approve its trade according to its own risk configuration.

The core runtime does not assume that one instance can observe or coordinate the decisions of the others.

## 14.1 Account-Level Financial Sharing

**Runtime independence does not mean financial independence.**

All Quantum instances may operate on the same MT5 account. Therefore:

* Account equity is shared.
* Account margin is shared.
* Broker constraints (spread, freeze level, stop level, execution mode) are shared.
* Account-level financial state is inherently shared, regardless of how independently each instance's code and runtime state are isolated.

This has a concrete consequence: any Risk Engine sizing model that uses account equity or balance (for example, Fixed Percentage Risk or Volatility Adjusted Risk — see Prompt 09) is reading a value that every other running instance also contributes to and draws from. Three instances each independently approving "0.50% risk" are not three financially independent decisions; they are three reads of the same shared, moving denominator, and each instance's open exposure affects the margin available to the others.

The core Quantum runtime does not pretend otherwise, and does not attempt to compensate for it. Symbol-scoped instances provide **runtime and state isolation**, not **portfolio-level risk isolation**. No document in this project shall describe symbol-scoped instances as providing financial independence between instances on the same account. Centralized portfolio coordination that would manage this shared exposure remains out of scope for V1 (Section 15) and may only be introduced through a dedicated future architectural extension and ADR.

---

# 15. Account-Level Controls

Account-level controls shall not be silently implemented inside a symbol-scoped engine.

If a future requirement demands controls such as:

```text
Maximum account daily loss
Maximum total Quantum exposure
Maximum correlated exposure
Maximum aggregate margin
```

the system shall introduce an explicitly designed account-level coordination mechanism.

Such functionality shall require:

1. Architectural analysis
2. New or modified contracts
3. ADR approval
4. Implementation review

The existing symbol-scoped architecture shall not be bypassed using hidden shared state.

---

# 16. Prohibited Cross-Instance Communication

The following mechanisms shall not be used to create undocumented coordination between Quantum instances:

* Hidden global variables
* Undocumented files used as shared state
* Implicit terminal-wide state
* Unspecified shared caches
* Direct manipulation of another instance's runtime objects
* Hidden inter-instance event channels

Any future cross-instance communication must be explicitly defined as part of the architecture.

## 16.1 Terminal-Wide Shared Storage

Two specific MQL5 mechanisms are named explicitly because they are easy to reach for without recognizing they are terminal-wide, not instance-local:

* `GlobalVariableSet()` / `GlobalVariableGet()` — the terminal's persistent global variable store, visible to every EA and script running in that terminal, distinct from ordinary code-level (in-process) global variables.
* Shared files opened with `FILE_COMMON` — written to the terminal's shared Common folder rather than the local `MQL5/Files` folder.

Neither shall be used for undocumented runtime coordination between Quantum instances, unless a future architectural decision explicitly defines and governs such usage. This does not prohibit ordinary code-level globals scoped within a single instance's own compiled program — MQL5 does not share that state across separate chart attachments, and it is not the concern this section addresses. The concern is specifically hidden terminal-wide state used to coordinate independent Quantum instances. No such mechanism shall be introduced now.

---

# 17. Position Ownership

Position Lifecycle shall operate within the ownership boundary of its Quantum instance.

A Quantum instance shall only manage positions that it is explicitly authorized to manage.

Position ownership should be identifiable through appropriate instance identity information such as:

* Strategy identifier
* Instance identifier
* Symbol
* Magic number
* Position metadata where appropriate

The implementation shall prevent one Quantum instance from unintentionally modifying positions belonging to:

* Another Quantum instance
* Another EA
* Manual trading activity

**MQL5 requirement.** MQL5's position, order, and history APIs (`PositionsTotal`, `PositionGetSymbol`, `PositionGetInteger`, `OrdersTotal`, `HistorySelect`, `OnTradeTransaction`) are terminal/account-wide. Being attached to a particular chart does not automatically guarantee that a position loop only sees the EA's own positions. Therefore every Quantum position/order/history operation must enforce ownership filtering. At minimum, the ownership rule is:

```text
Symbol == Instance.Symbol
AND
Magic == Instance.Magic
```

Implementation shall use the appropriate MQL5 APIs and data access patterns to enforce this on every such operation; chart attachment alone shall never be assumed to provide sufficient isolation. This mechanism must be explicit and testable.

## 17.1 Restart Recovery

The existing testing prompts (Prompt 12, Robustness Testing) already list "Restart recovery," "Platform restart," and "Chart refresh" as required test cases, but no document previously defined what successful recovery means. This section is that definition.

On initialization or restart, a Quantum instance must be capable of reconstructing its relevant Position Lifecycle state from actual broker/terminal state — implementation shall not assume that all runtime state starts empty after a restart. Conceptually:

```text
OnInit
  ↓
Resolve Instance Identity
  ↓
Resolve Symbol
  ↓
Discover Existing Positions
  ↓
Filter by Symbol + Magic / Ownership
  ↓
Reconstruct Position State
  ↓
Resume Normal Processing
```

Rules that follow from this:

* A broker-side position matching the instance's symbol but **not** its magic/instance identity is never this instance's position, and is never touched, even if no in-memory record of it exists.
* A broker-side position matching the instance's identity with **no** corresponding decision record on file is orphaned state. It shall be logged and surfaced through Observability. It shall never be silently adopted, and never silently ignored.
* If an instance's configuration has changed since a still-open position was opened under the prior configuration, the position's broker-side state remains authoritative; the new configuration applies prospectively to future decisions, not retroactively to an already-open position, unless a specific engine is explicitly designed to do otherwise.

This is a contract requirement, not merely a test case. It is defined further, at the field level, in `Contracts/Shared Data Objects.md`.

---

# 18. Magic Number / Instance Identity

Each Quantum instance shall have a unique trading identity sufficient to distinguish its positions from other trading activity, **and** sufficient to distinguish it from any other Quantum instance — including another Quantum instance on the same symbol (Section 6.1).

The identity model shall support:

```text
Strategy ID
Instance ID
Symbol
Magic Number
```

`Symbol` alone is not sufficient runtime identity. The Magic Number / instance identity scheme must allow Quantum to distinguish:

* Quantum Instance A from Quantum Instance B, including when both run on the same symbol
* Quantum positions from manual positions
* Quantum positions from other EAs
* One strategy version from another, where required

For example:

```text
Quantum
Strategy = Q01
Symbol   = EURUSD
Magic    = 210001
```

and:

```text
Quantum
Strategy = Q01
Symbol   = XAUUSD
Magic    = 210002
```

and, per Section 6.1:

```text
Quantum
Strategy = Q01
Symbol   = EURUSD
Instance = A
Magic    = 210001

Quantum
Strategy = Q01
Symbol   = EURUSD
Instance = B
Magic    = 210002
```

The final identifier-generation mechanism shall be defined by the Execution and Position Lifecycle contracts. It shall be deterministic, explicit, and MQL5-friendly. It shall not be an unnecessarily complicated identity framework.

---

# 19. Event Scope

Events generated inside a Quantum runtime shall be considered instance-scoped unless explicitly defined otherwise.

For example:

```text
EURUSD Market Update
```

belongs to the EURUSD Quantum instance.

It shall not implicitly become:

```text
GBPUSD Market Update
XAUUSD Market Update
```

Events shall not cross runtime boundaries without an explicitly approved architectural mechanism. For V1, every event defined in `Contracts/Event Definitions.md` is instance-scoped; any future account/global-scoped event requires an explicit architectural extension and its own ADR, per Section 12 and Section 15.

---

# 20. Configuration Scope

Configuration shall be divided conceptually into:

### Instance Configuration

Configuration directly affecting one Quantum runtime.

Examples:

* Symbol-specific parameters
* Timeframe settings
* Strategy parameters
* Risk parameters
* Model parameters
* Execution settings

### Global Platform Configuration

Any future configuration affecting multiple instances shall be explicitly identified as global.

Global configuration must not be introduced implicitly through instance modules.

---

# 21. Dashboard Scope

The default Quantum Dashboard shall display information for its owning symbol instance.

For example:

```text
Quantum Dashboard

Symbol: EURUSD
Regime: Bullish
Structure: BOS
Liquidity: Buy-side Sweep
Quality: 82
Risk: 0.50%
Execution: Ready
```

The dashboard shall not require knowledge of all other Quantum instances.

A future portfolio dashboard may be created separately if justified.

---

# 22. Statistics Scope

Statistics shall primarily belong to the Quantum instance that generated the underlying trades and decisions.

For example:

```text
EURUSD Statistics

Trades: 87
Win Rate: 72%
Expectancy: ...
Drawdown: ...
Profit Factor: ...
```

Separate symbols shall maintain separate statistics.

Portfolio-level statistics may be calculated later through an external aggregation or dedicated analytics layer without changing the core symbol-scoped runtime model.

---

# 23. Testing Implications

The symbol-scoped architecture simplifies testing.

An engine can be tested against:

```text
Symbol
+
Configuration
+
Market Snapshot
+
Historical State
```

without requiring an entire portfolio environment.

For example:

```text
Test Case

Symbol: EURUSD
Timeframe: M15
Snapshot: Historical Snapshot #1421

Expected:
Structure = Bullish BOS
Liquidity = Sell-side Sweep
Quality = 81
Risk = Approved
```

The same engine implementation can then be tested against:

```text
GBPUSD
XAUUSD
USDJPY
```

independently.

---

# 24. Failure Isolation

One of the primary advantages of symbol-scoped execution is failure isolation.

If an individual Quantum instance encounters an operational problem:

```text
EURUSD Quantum
      ↓
Failure
```

the architecture does not require:

```text
GBPUSD Quantum
XAUUSD Quantum
USDJPY Quantum
```

to fail with it.

Independent runtime instances therefore reduce the blast radius of runtime faults.

---

# 25. Performance Implications

Each instance processes only the market context required by its own symbol.

This provides several advantages:

* Smaller working state
* Lower per-instance complexity
* Easier profiling
* Easier debugging
* Localized calculations
* Simpler memory management

Running many instances naturally increases total terminal resource usage, but the architecture remains conceptually simple.

Performance optimization shall therefore focus first on the efficiency of each independent instance.

---

# 26. Implementation Implications

The implementation shall reflect this architecture at the Kernel level.

Conceptually:

```text
QuantumEA
    │
    └── QuantumKernel
            │
            ├── Configuration
            ├── Market Data
            ├── Regime
            ├── Structure
            ├── Liquidity
            ├── Institutional Models
            ├── Trade Quality
            ├── Risk
            ├── Execution
            ├── Position Lifecycle
            └── Statistics
```

The Kernel instance shall be initialized for one symbol and shall own the lifecycle of its engines.

---

# 27. Architectural Boundary

The following boundary shall be considered fundamental:

```text
┌─────────────────────────────────────────────┐
│            Quantum Instance                 │
│                                             │
│  Symbol = ONE                               │
│                                             │
│  ┌───────────────────────────────────────┐  │
│  │ Market Data                           │  │
│  │ Regime                                │  │
│  │ Structure                             │  │
│  │ Liquidity                             │  │
│  │ Institutional Models                  │  │
│  │ Trade Quality                         │  │
│  │ Risk                                  │  │
│  │ Execution                             │  │
│  │ Position Lifecycle                    │  │
│  │ Statistics                            │  │
│  └───────────────────────────────────────┘  │
│                                             │
└─────────────────────────────────────────────┘

        ║              ║              ║
        ║              ║              ║
        ▼              ▼              ▼

    EURUSD         GBPUSD          XAUUSD
    Instance       Instance        Instance
```

Each box is independent.

---

# 28. Consequences

## 28.1 Positive Consequences

### Simpler Architecture

Each runtime has one clear symbol boundary.

### Strong Isolation

Symbol state cannot accidentally leak between instances.

### Easier Testing

Engines can be validated independently.

### Easier Debugging

Logs and decisions naturally map to one symbol.

### Easier AI Review

AI reviewers can reason about a single runtime without reconstructing a multi-symbol system.

### Easier Deployment

The same EA can be attached to any supported symbol.

### Better Failure Isolation

A problem in one instance does not inherently require the entire platform to stop.

### Lower Complexity

No central multi-symbol orchestration is required for core operation.

---

## 28.2 Negative Consequences

The architecture does not automatically provide:

* Portfolio-level risk
* Cross-symbol correlation management
* Centralized account coordination
* Cross-instance strategy allocation

Running many symbols also means running multiple Quantum instances, increasing total CPU and memory usage.

Account equity, margin, and broker-level constraints are inherently shared across every instance running on the same MT5 account; running multiple instances provides runtime and state isolation, not financial isolation (Section 14.1). This is not solved by this architecture — it is an accepted property of running independent instances against one account.

These are accepted tradeoffs for architectural simplicity and runtime independence.

---

# 29. Alternatives Considered

## Alternative A — Centralized Multi-Symbol Quantum

```text
One EA
  │
  ├── EURUSD
  ├── GBPUSD
  ├── XAUUSD
  └── USDJPY
```

### Rejected

Reasons:

* Higher complexity
* Larger state surface
* More complicated event routing
* More difficult testing
* More difficult debugging
* Greater AI context requirements
* Greater coupling
* Unnecessary for core V1 requirements

---

## Alternative B — Hybrid Centralized Portfolio Engine

```text
Central Quantum
      │
      ├── EURUSD Instance
      ├── GBPUSD Instance
      └── XAUUSD Instance
```

### Deferred

This could eventually provide portfolio-level coordination, but it is not required for the core Quantum runtime.

Introducing it now would add complexity before a demonstrated requirement exists.

If portfolio coordination becomes necessary, it shall be introduced through a future ADR.

---

## Alternative C — Symbol-Scoped Independent Runtime

```text
EURUSD → Quantum
GBPUSD → Quantum
XAUUSD → Quantum
```

### Selected

Reasons:

* Strong isolation
* Low coupling
* Simple runtime model
* Easy testing
* Easy debugging
* Natural MQL5 deployment model
* Suitable for solo development
* Compatible with existing architectural philosophy
* Minimal unnecessary infrastructure

---

# 30. Impact on Existing Architecture

This ADR does **not** redesign the Project Quantum architecture.

It clarifies an existing runtime assumption, and corrects two places where existing documents (`SYSTEM_ARCHITECTURE.md` Section 8's prior Risk Engine description, and `IMPLEMENTATION_ARCHITECTURE.md`'s prior Phase 7 roadmap) had already committed to the alternative this ADR rejects. Those corrections are recorded in Section 37.

The following architectural principles remain unchanged:

* Modular engine boundaries
* Evidence-based decision flow
* Frozen market snapshots
* Explicit state ownership
* Deterministic processing
* Separation of analysis and execution
* No black-box live learning
* No unnecessary infrastructure

Only the runtime scope is made explicit.

---

# 31. Required Documentation Updates

The following documents were reviewed for consistency with this ADR and reconciled as of the Amended date above (Section 37 records the change log):

### Reconciled

* `SYSTEM_ARCHITECTURE.md` — Section 2 (Scope) clarified; Section 6 (Platform Layer) given an explicit runtime-instance-scope paragraph; Section 8 Risk Engine entry corrected to remove account-wide/correlation guardrails; Section 8 Position Lifecycle Engine and Kernel entries given explicit restart-recovery and runtime-identity ownership; Section 16 given a new position/order isolation constraint.
* `IMPLEMENTATION_ARCHITECTURE.md` — Chapter 6 given a new 6.5 Runtime Instance Scope subsection and a new Prohibited Practice; Chapter 7 given a new 7.7 Restart Recovery subsection; Chapter 23's Phase 7 roadmap no longer schedules a Portfolio Manager component.
* `Contracts/Shared Data Objects.md` — RuntimeIdentity and RiskState added; PositionState given ownership fields and a restart-recovery contract.
* `Contracts/Engine Contract.md` — Runtime Scope and Lifecycle (including restart recovery) added to the minimum contract every engine must state.
* `Contracts/Event Definitions.md` — every event given an explicit scope, producer, consumer, trigger, payload, and ordering statement.
* `Prompt 09 — Risk Management & Trade Management Engine.md` — restructured into two explicitly separate specifications (Risk Engine, pre-trade only; Position Lifecycle Engine, post-fill only); portfolio/correlation content removed from active scope and recorded as deferred.

### Specific Corrections Made

The Risk Engine documentation no longer implies that the core Risk Engine provides portfolio-wide cross-symbol correlation management.

Prompt 09 has been reconciled with the separation between:

```text
Risk Engine
```

and:

```text
Position Lifecycle Engine
```

The corrected implementation flow is:

```text
Analysis
   ↓
Decision
   ↓
Risk
   ↓
Execution
   ↓
Position Lifecycle
```

---

# 32. Required Contract Updates

The following runtime concepts are now represented explicitly in `Contracts/Shared Data Objects.md`, `Contracts/Engine Contract.md`, and `Contracts/Event Definitions.md`:

**Runtime Identity** — Strategy ID, Instance ID, Symbol, Magic Number, resolved once at `OnInit` and immutable for the runtime's lifetime.

**Position Ownership** — Symbol, Magic/Instance Identity, Position Ticket, Lifecycle State; every position/order/history operation filters on Symbol + Magic before acting.

**Restart Recovery** — what state must be reconstructed, what broker state is authoritative, how owned positions are discovered, how orphaned/inconsistent state is handled, and what happens if configuration no longer matches an existing position.

**Event Scope** — every event explicitly marked instance-scoped (the only scope defined for V1) or, in the future, account/global-scoped.

These are intentionally minimal: no enterprise DTO framework, no fields beyond what the above four concepts require.

---

# 33. Future Extension Policy

This ADR does not prohibit future portfolio-level architecture.

It establishes that such functionality must be introduced deliberately.

Future requirements such as:

* Portfolio risk
* Cross-symbol correlation
* Aggregate exposure
* Centralized allocation
* Multi-symbol analytics
* Portfolio optimization

shall be evaluated independently.

If implementation requires cross-instance coordination, a new ADR or amendment shall be created.

No hidden coordination shall be introduced.

---

# 34. Implementation Rule

From the approval of this ADR onward:

> **Every Quantum runtime engine shall be designed and implemented with the assumption that it belongs to exactly one Quantum symbol instance.**

An engine may consume shared code and shared immutable definitions.

It shall not assume access to another symbol's runtime state.

---

# 35. Final Decision Statement

Project Quantum adopts a **symbol-scoped independent runtime architecture**.

The platform shall support multiple symbols by running multiple independent Quantum EA instances. Multiple independently identified instances may also run on the same symbol (Section 6.1).

Each instance shall:

* Own exactly one symbol.
* Own its runtime state and runtime identity (Strategy ID, Instance ID, Magic Number).
* Analyze its own market data.
* Generate its own decisions.
* Calculate its own trade risk, using account information available to it, without assuming financial independence from other instances on the same account (Section 14.1).
* Execute its own trades.
* Manage its own positions, enforcing symbol + magic/instance ownership filtering on every position/order/history operation (Section 17).
* Reconstruct its position lifecycle state from broker truth after any restart (Section 17.1).
* Maintain its own statistics.
* Maintain its own observability state.

No core engine shall require cross-symbol runtime coordination.

Portfolio-level functionality is outside the scope of the core runtime and may only be introduced through a future explicitly approved architectural extension and its own ADR.

This decision preserves Project Quantum's fundamental engineering principles:

> **Deterministic. Modular. Explainable. Independent. Maintainable. AI-reviewable. Pragmatic.**

---

# 36. Status

**Status:** Accepted, effective 2026-08-12.

This ADR became Accepted after:

1. Chief System Architect review. ✓
2. Principal Software Engineer review. ✓ (identified the contradictions and gaps resolved in this amendment)
3. Project Owner approval. ✓
4. Required documentation reconciliation. ✓ (Section 31, completed 2026-08-12 — see Section 37)

This ADR is now part of the architectural foundation of Project Quantum. Amendments to it follow the same review chain as its original adoption.

---

# 37. Amendment Log

**2026-08-12 — Reconciliation Pass.** Prompted by Principal Software Engineer review, which found:

* A direct contradiction between `SYSTEM_ARCHITECTURE.md` Section 8's original Risk Engine description (which listed account-level daily loss, correlation exposure, and maximum concurrent risk as things the Risk Engine already owned) and this ADR's Sections 14–15 (which place those items out of core V1 scope).
* `IMPLEMENTATION_ARCHITECTURE.md`'s Phase 7 roadmap scheduling a "Portfolio Manager" component with no corresponding engine in `SYSTEM_ARCHITECTURE.md`'s Section 8 engine list and no ADR authorizing it.
* `Prompt 09` combining Risk Engine and Position Lifecycle Engine into one module, and specifying an entire portfolio/correlation scope (Portfolio Risk Allocation, a full "PORTFOLIO RISK" section, and a full "CORRELATION MANAGEMENT" section) that cannot be computed inside a single symbol-scoped instance.
* No document defining what "restart recovery" — already required as a test case in Prompt 12 — actually means in terms of state reconstruction.
* No contract representation anywhere for Runtime Identity or Position Ownership, despite Sections 17–18 requiring them.
* An implicit assumption, in Section 14's framing, that symbol-scoped instances provide more independence than the shared-MT5-account model actually allows.

This amendment: added Section 6.1 (Multiple Instances on the Same Symbol), Section 14.1 (Account-Level Financial Sharing), Section 16.1 (Terminal-Wide Shared Storage), and Section 17.1 (Restart Recovery); amended Section 18 to state explicitly that Symbol alone is not sufficient identity; amended Section 28.2 to acknowledge shared account-level financial state as an accepted, unsolved consequence; restated Sections 31–32 as a completed reconciliation record; and changed Status (Section 36) to Accepted. No section describing the core decision (Sections 1–5) was altered. Prior rationale in this document has been preserved, not deleted, consistent with `SYSTEM_ARCHITECTURE.md` Section 17's versioning principle.

---

# End of ADR-001