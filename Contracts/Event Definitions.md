# Event Definitions

## Event Scope (applies to every event below)

Every event listed here is **instance-scoped** unless explicitly marked otherwise. An event produced by a Quantum runtime instance belongs to that instance's Symbol, Strategy ID, and Instance ID; it is never implicitly broadcast to, or assumed relevant by, another instance (ADR-001, Section 19). No event in this document is account/global-scoped. Introducing an account/global-scoped event requires an explicit architectural extension and its own ADR (ADR-001, Sections 12 and 15).

Each event is a one-way notification of a state change, not a request/response call, consistent with SYSTEM_ARCHITECTURE.md Section 10's event philosophy. The Kernel remains the single dispatcher; this is not a generalized publish/subscribe bus.

## Standard Events

| Event | Scope | Producer / Owner | Consumer(s) | Trigger | Payload (conceptual) | Ordering |
|---|---|---|---|---|---|---|
| `OnNewTick` | Instance | Platform Layer | Kernel | New tick received for the instance's Symbol | MarketContext (raw) | Precedes `OnBarClose` when a bar also closes on this tick |
| `OnBarClose` | Instance | Platform Layer | Kernel, all Analysis engines | Working timeframe bar closes | MarketContext (frozen snapshot) | Fires once per closed bar; Analysis engines run only in response to this event, never on raw ticks |
| `OnStructureUpdated` | Instance | Market Structure Engine | Trade Quality Engine | Structure snapshot changes | StructureSnapshot | After `OnBarClose`, before Trade Quality Engine runs |
| `OnLiquidityUpdated` | Instance | Liquidity Engine | Trade Quality Engine | Liquidity snapshot changes | LiquiditySnapshot | After `OnBarClose`, before Trade Quality Engine runs |
| `OnContextUpdated` | Instance | Session/Context Engine | Trade Quality Engine | Session or contextual snapshot changes | Context evidence | After `OnBarClose`, before Trade Quality Engine runs |
| `OnTradeDecision` | Instance | Trade Quality Engine | Risk Engine | Qualification verdict produced (qualified or rejected) | TradeDecision (with EvidencePacket bundle) | After all Analysis engine events for the current cycle |
| `OnPositionOpened` | Instance | Execution Engine | Position Lifecycle Engine, Statistics Engine, Dashboard | Order fill confirmed by the terminal | PositionState (referencing the originating RiskState/TradeDecision) | After Risk Engine approval and terminal fill confirmation |
| `OnPositionClosed` | Instance | Position Lifecycle Engine | Statistics Engine, Dashboard | Position fully closed | Closed-trade record (PositionState with LifecycleState = Closed) | Terminal event for that position's lifecycle |
| `OnStatisticsUpdated` | Instance | Statistics Engine | Dashboard, Learning Layer | A new closed-trade record has been processed | Updated statistics summary | After `OnPositionClosed` |

The Producer column also denotes the owner of that event's payload shape, consistent with SYSTEM_ARCHITECTURE.md Section 11's one-owner-per-object rule — no other engine may define its own version of an event's payload.