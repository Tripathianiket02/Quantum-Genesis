# Shared Data Objects

Core shared objects, each owned by exactly one engine (SYSTEM_ARCHITECTURE.md Section 11). No engine may invent a duplicate version of any object below. This document favors a small number of meaningful objects over an enterprise DTO framework — fields exist only where ADR-001 or SYSTEM_ARCHITECTURE.md requires them.

## RuntimeIdentity

**Owner:** Platform Layer / Configuration Engine. Resolved once at `OnInit`; immutable for the runtime's lifetime (SYSTEM_ARCHITECTURE.md Section 6, "Symbol Binding"; ADR-001).

| Field | Type | Meaning |
|---|---|---|
| `Symbol` | string | The one trading symbol this instance is bound to. |
| `StrategyID` | string / enum | Identifies which strategy/codebase this instance runs. |
| `InstanceID` | string / int | Distinguishes this instance from any other instance of the same StrategyID — required when multiple instances share a Symbol (ADR-001, Section 6.1). |
| `MagicNumber` | integer | Deterministic identifier derived from StrategyID + Symbol + InstanceID; tags every order and position this instance places. |

**Rule that depends on this object:** every engine that enumerates positions, orders, or history must filter using `Symbol == RuntimeIdentity.Symbol AND Magic == RuntimeIdentity.MagicNumber` before acting on any result (ADR-001, Section 17). Chart attachment alone never substitutes for this filter.

## MarketContext ("Market Snapshot")

**Owner:** Platform Layer. **Mutability:** immutable once published for its cycle (SYSTEM_ARCHITECTURE.md Section 11, "Snapshots").

Conceptually carries a cycle/snapshot identifier, `RuntimeIdentity.Symbol`, the working timeframe, and the price and account state at that instant. Every Analysis engine within a cycle reads the same frozen MarketContext — none may re-query live prices mid-cycle.

## StructureSnapshot / LiquiditySnapshot / ZoneSnapshot

**Owner:** the respective Analysis engine (Market Structure / Liquidity / Institutional Zones). Each references the MarketContext cycle it was derived from. Produced once per cycle; not retroactively edited (Section 11, "Data immutability where practical").

## EvidencePacket

**Owner:** the producing Analysis engine. Conceptually carries a claim, a confidence value, and a reference to the producing engine and the MarketContext cycle it was derived from (SYSTEM_ARCHITECTURE.md Section 11, "Evidence"). Never a bare boolean or number — every evidence claim is traceable to the engine and cycle that produced it.

## TradeDecision ("Decision State")

**Owner:** Trade Quality Engine. Carries the qualifying (or rejecting) EvidencePacket bundle, aggregate confidence, and the parameters the Risk Engine needs to size the trade. Logged in full at creation, before Risk or Execution runs (SYSTEM_ARCHITECTURE.md Section 11).

## RiskState

**Owner:** Risk Engine. Produced once per TradeDecision.

| Field | Type | Meaning |
|---|---|---|
| `Approved` | bool | Whether the Risk Engine approved the trade. |
| `LotSize` | double | Approved position size, if approved. |
| `RiskAmount` | double | Monetary or percentage risk committed, if approved. |
| `StopPrice` / `TargetPrice` | double | Derived from the selected stop/target model. |
| `RejectionReason` | enum / string | The specific limit that rejected the trade, if not approved. |
| `SourceDecisionRef` | reference | The TradeDecision this assessment evaluated. |

Logged in full at creation, before Execution runs, so a rejection is exactly as reconstructable as an approval. `RiskState` never carries cross-symbol or portfolio-level fields — see ADR-001, Sections 13–15.

## PositionState

**Owner:** Position Lifecycle Engine, from the moment Execution confirms a fill.

| Field | Type | Meaning |
|---|---|---|
| `Symbol` | string | From RuntimeIdentity — must match the owning instance. |
| `MagicNumber` | integer | From RuntimeIdentity — must match the owning instance. |
| `PositionTicket` | ulong | Broker-assigned ticket; the authoritative reference for this position. |
| `LifecycleState` | enum | e.g. `Opened` / `Managed` / `PartiallyClosed` / `Closed` — the Position Lifecycle Engine's own management phase, not a broker concept. |
| `SourceRiskStateRef` | reference | The RiskState (and, through it, the TradeDecision) that originated this position. |

**Mutability:** mutable while the position is open; becomes an immutable historical record once `LifecycleState = Closed` (Section 11). This closed record is the "closed-trade record" the Statistics Engine consumes — no separate object is defined for that purpose.

**Restart recovery (ADR-001, Section 17.1):** on `OnInit`, any broker-side position matching this instance's RuntimeIdentity (Symbol + MagicNumber) must have its PositionState reconstructed from broker truth — ticket, open price, volume, current stop/target — rather than assumed empty.

* A position matching `Symbol` but not `MagicNumber` is never this instance's, and is never touched, even with no in-memory record.
* A position matching this instance's RuntimeIdentity with no corresponding `SourceRiskStateRef` on file is **orphaned state**: it must be logged and surfaced through Observability. It is never silently adopted, and never silently ignored. The specific recovery action taken (e.g., adopt into a fresh minimal lifecycle record vs. flag for manual review) is an implementation decision within this contract's boundary, not a policy this contract mandates.
* If configuration has changed since the position was opened, the broker-side fields above remain authoritative; new configuration applies to future decisions, not retroactively to this position.

## LearningObservation

**Owner:** Learning Layer. Derived from closed PositionState records via the Statistics Engine. Feeds future Configuration only — never a live in-session decision (SYSTEM_ARCHITECTURE.md Section 6, "Learning Layer").