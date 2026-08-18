# SYSTEM_ARCHITECTURE.md

Status:
APPROVED

Version:
1.0

Architecture State:
FROZEN

**Project Quantum — Architectural Constitution**

| Field | Value |
|---|---|
| Document Status | Authoritative — Highest Architectural Authority |
| Document Type | Engineering Constitution |
| Language | Pure MQL5 |
| Maintainer | Solo Developer, AI-Assisted |
| Supersedes | All prior architectural notes, diagrams, and verbal agreements |
| Applies To | Every engine, module, script, and include file in Project Quantum |

---

### Table of Contents

1. Introduction
2. Project Identity
3. Architectural Vision
4. Core Architectural Principles
5. Non-Goals
6. High-Level Architecture
7. Engine Architecture
8. Engine List
9. Engine Communication Rules
10. Event Philosophy
11. Data Philosophy
12. Evidence-Based Decision Model
13. Coding Standards
14. Repository Organization
15. AI Collaboration Workflow
16. Architectural Constraints
17. Evolution Policy
18. Definition of Architectural Success
19. Governance
20. Final Statement

---

## 1. Introduction

Project Quantum is a modular, institutional-inspired quantitative trading platform written entirely in MQL5. It is not a single Expert Advisor bolted together from indicator signals. It is a system: a set of cooperating engines that observe the market, build evidence, weigh that evidence, and act on it through a disciplined, auditable execution path.

This document exists because a one-developer project has no second reviewer, no architecture board, and no institutional memory beyond what is written down. Without a constitution, architecture drifts one convenient shortcut at a time until the system becomes unexplainable, untestable, and untrustworthy with real capital. This document is the mechanism that prevents that drift.

This is the highest architectural authority in Project Quantum. Where code disagrees with this document, the code is wrong. Where a design conversation with an AI assistant disagrees with this document, this document wins unless this document itself is formally revised. No engine, no feature, and no optimization is permitted to violate the rules stated here without first amending this constitution through the process defined in Section 17.

This document does not describe how to implement Project Quantum. It describes what Project Quantum is, why it is shaped the way it is, and what boundaries every future change — human-written or AI-assisted — must respect.

---

## 2. Project Identity

**Platform identity.** Project Quantum is a quantitative execution platform. It is the operating system for a single trader's rule-based decision-making, expressed in code. It is not a signal generator, not an indicator pack, and not an Expert Advisor in the traditional MetaTrader sense of "one file, one strategy, one chart." It is an integrated system of specialized engines operating under a shared kernel.

**Scope.** Project Quantum covers the full lifecycle of a trading decision: market observation, structural and contextual analysis, evidence aggregation, trade qualification, execution, position management, statistical feedback, and operator-facing observability. It runs on the MetaTrader 5 platform, in MQL5, on live or historical price data, on one or more timeframes. Each running Quantum runtime instance operates on exactly one trading symbol; the platform supports multiple instruments by running multiple independent runtime instances, never by a single runtime instance operating across several symbols internally (ADR-001, Symbol-Scoped Runtime Architecture).

**Purpose.** The purpose of Project Quantum is to remove ad-hoc, emotional, or undocumented decision-making from trading and replace it with a deterministic, inspectable process that a single developer can trust, audit, and improve over time.

**Long-term objective.** The long-term objective is not "more features." It is a platform that, remains understandable by its original author, extensible without rewrites, and reliable enough that every trade it takes can be explained after the fact using nothing but its own logs and evidence trail.

Project Quantum is not merely automation of a strategy. It is infrastructure for decision-making under uncertainty, built to institutional standards of rigor and scaled to what one disciplined developer can actually build, test, and maintain.

---

## 3. Architectural Vision

The architecture exists to serve four qualities, in this order of priority when they conflict: clarity, determinism, explainability, and engineering discipline.

**Clarity.** Any engine in the system must be understandable in isolation. A developer — human or AI — reading one engine's source should not need to hold the entire system in their head to understand what that engine does, what it depends on, and what it produces. Clarity is achieved through strict boundaries, not through comments explaining tangled logic.

**Determinism.** Given the same market data, the same configuration, and the same historical state, Project Quantum shall produce the same decisions. Non-determinism is treated as a defect, not a characteristic of markets. Where true randomness would otherwise be introduced (for example in randomized backtesting perturbations), it must be seeded and logged, never silent.

**Explainability.** Every trade Project Quantum takes must be traceable to the evidence that produced it. "The system decided to buy" is not an acceptable internal explanation. "The Market Structure Engine reported a bullish break of structure with 0.72 confidence, the Liquidity Engine confirmed a swept low, and the Trade Quality Engine scored the setup at 0.81 against a 0.65 threshold" is the standard of explanation this architecture requires.

**Engineering discipline.** Discipline means the architecture is followed even when a shortcut would be faster. A one-developer project has no code review gate except the developer's own adherence to this document. That adherence is the only quality control Project Quantum has, and it is treated as non-negotiable.

The architectural vision deliberately rejects cleverness for its own sake. A clever architecture that only its author can reason about on a good day is a liability. A plain, well-bounded architecture that can be reasoned about on a bad day, under stress, at 2 a.m. during a live trading incident, is the goal.

---

## 4. Core Architectural Principles

Every principle below is binding. They are not aspirations; they are constraints that every engine, module, and change must satisfy.

### 4.1 Deterministic Design

Every engine shall produce identical output given identical input and identical prior state. Engines shall not read wall-clock time, external files, or non-reproducible sources mid-calculation unless that source is itself part of the recorded input (for example, a timestamped tick). Backtests and live runs over the same data must produce the same decisions.

*Failure mode prevented:* a backtest that looks profitable but cannot be reproduced, because some engine quietly depended on execution timing, iteration order, or terminal state that changes between runs.

### 4.2 Explainable Decisions

Every decision-relevant output — a signal, a score, a rejection, a trade — shall carry a reason. A reason is not a free-text comment written after the fact; it is structured evidence attached at the moment the decision is made. If an engine cannot explain why it produced a value, that engine is not finished.

*Failure mode prevented:* a losing trade that cannot be diagnosed because nothing recorded why the system believed it was a good idea in the first place.

### 4.3 Evidence-Driven Analysis

Engines shall base conclusions on observable, quantifiable market evidence — price structure, liquidity behavior, volatility regime, session context — never on unverifiable intuition encoded as a magic constant. Every threshold and weight used to interpret evidence shall be named, documented, and owned by a specific engine.

*Failure mode prevented:* a threshold tuned once by eye on a handful of chart examples, quietly ossifying into "the way it's always been" with no record of why.

### 4.4 Single Responsibility

Every engine shall have exactly one primary responsibility. An engine that both detects market structure and manages open positions is two engines wearing one name, and it shall be split. If describing an engine's job requires the word "and" applied to two unrelated verbs, the engine is doing too much.

*Failure mode prevented:* a change intended to improve trailing-stop behavior that silently breaks structure detection, because the two were never actually separate.

### 4.5 Modularity

Every engine shall be a self-contained unit with a defined interface, replaceable without modifying the engines around it. Modularity is verified by a simple test: could this engine be deleted and replaced with a different implementation of the same interface without touching any other engine's source code? If not, the boundary is wrong.

*Failure mode prevented:* rewriting the Liquidity Engine's internal algorithm requiring edits to the Trade Quality Engine, the Dashboard, and three other files that had no business knowing how liquidity was calculated.

### 4.6 Loose Coupling

Engines shall depend on interfaces and shared data contracts, not on each other's internals. No engine shall reach into another engine's private state. Communication happens only through the channels defined in Section 9.

*Failure mode prevented:* a private variable inside one engine being read directly by another, so that renaming or restructuring that variable breaks a module its author never knew was watching it.

### 4.7 High Cohesion

Everything inside an engine shall relate directly to that engine's single responsibility. Utility code that does not belong to the engine's purpose shall live in a shared utility module, not be duplicated or smuggled into an unrelated engine.

*Failure mode prevented:* the same price-rounding helper reimplemented four different ways across four engines, each with a slightly different bug.

### 4.8 Long-Term Maintainability

Code shall be written for the developer reading it from now with no memory of writing it. Maintainability outranks micro-optimization. An engine that is 5% slower but immediately understandable is preferred over an engine that is 5% faster and requires a diagram to explain.

*Failure mode prevented:* the owner afraid to touch a working but unreadable engine, so bugs in it are patched around rather than fixed.

### 4.9 Testability

Every engine shall be testable in isolation, against synthetic and historical data, without requiring the full platform to be running. If an engine cannot be exercised by a standalone test script, its interface is too entangled with the rest of the system.

*Failure mode prevented:* a regression in the Risk Engine's position sizing that is only discovered when a live trade is sized incorrectly.

### 4.10 Statistical Validation

Claims about an engine's effectiveness shall be backed by statistics gathered over a meaningful sample, not by inspection of a handful of favorable chart examples. The Statistics Engine (Section 8) exists specifically to make this principle enforceable rather than aspirational.

*Failure mode prevented:* keeping or discarding an evidence source based on five memorable trades instead of the several hundred the Statistics Engine actually has on record.

### 4.11 Architecture Before Optimization

Performance work is only permitted after architectural correctness is established. An engine shall never be restructured for speed in a way that breaks single responsibility, determinism, or explainability. If a performance problem cannot be solved without violating architecture, the correct fix is a better algorithm inside the existing boundaries, not a boundary violation.

*Failure mode prevented:* a tick-processing shortcut that shaves microseconds off `OnTick` by having the Execution Engine read raw price data directly, quietly bypassing the evidence pipeline that made the system explainable.

### 4.12 Pragmatic Simplicity

The simplest architecture that satisfies the other principles is the correct architecture. Complexity shall be introduced only when a real, current requirement demands it — never in anticipation of a hypothetical future need. This principle is the direct architectural expression of the Solo Developer Constraint in Section 1 of this project's founding scope.

*Failure mode prevented:* months spent building a generic multi-strategy plugin framework for hypothetical future strategies that never materialize, while the one strategy that exists today stays unfinished.

### 4.13 AI Reviewability Principle

Because Project Quantum is built with AI assistance, every engine shall be structured so that an AI collaborator can read it, understand its boundaries, and propose changes without access to the rest of the codebase. This means: explicit interfaces, explicit inputs and outputs, no reliance on implicit global state, and documentation that states purpose before it states detail. An architecture that only a human with full context can safely modify has failed this principle.

*Failure mode prevented:* an AI assistant given one engine's file in isolation, unable to tell what it depends on or produces, and forced to guess — with guesses that quietly introduce Section 9 violations.

---

## 5. Non-Goals

A constitution is defined as much by what it forbids as by what it requires. Project Quantum explicitly does **not** pursue the following, and any proposal that reintroduces them shall be rejected at design review.

* **No black-box AI.** Project Quantum does not delegate trade decisions to opaque machine learning models whose reasoning cannot be inspected. Statistical learning is permitted; unexplainable inference is not.
* **No over-engineering.** Patterns are adopted because they solve a problem this platform actually has, not because they are considered best practice in a different class of system.
* **No unnecessary abstraction.** An interface is introduced when there are real, current implementations that need to vary. Interfaces built "in case we need it later" are removed.
* **No feature creep.** A new capability is added because it strengthens the core decision pipeline, not because it is technically interesting to build.
* **No architecture for problems we do not have.** Project Quantum has one developer, one runtime, and one deployment target: the MetaTrader 5 terminal. It shall not be architected as if it had ten engineers, multiple deployment environments, or a distributed user base.
* **No enterprise infrastructure.** No microservices, no containers, no orchestration layers, no message queues external to the terminal process, no database clusters. Section 1's Solo Developer Constraint is absolute and is repeated here because it is the single most common source of architectural drift in ambitious solo projects.
* **No execution logic in analysis code, and no analysis logic in execution code.** These are different concerns, addressed formally in Section 9 and Section 16.
* **No premature generalization across instruments or strategies.** Project Quantum is built to be extensible, but extensibility is proven by refactoring toward it when a second real case appears, not by speculative generalization before the first case is finished.

---

## 6. High-Level Architecture

Project Quantum is organized into six layers. Each layer has a distinct responsibility, and data flows through them in a controlled, mostly one-directional path, with feedback loops explicitly designed rather than incidental.

**Platform Layer.** This layer is the boundary between Project Quantum and the MetaTrader 5 terminal itself. It owns all direct interaction with terminal events (`OnInit`, `OnTick`, `OnTimer`, `OnTradeTransaction`, `OnDeinit`), symbol and account information, and terminal-provided market data. No other layer talks to the terminal directly. This is the only layer permitted to know that MetaTrader exists.

**Analysis Layer.** This layer observes market state and produces descriptive, non-directive evidence: regime classification, structural state, liquidity conditions, institutional zone mapping, and session context. Analysis engines describe what the market is doing. They do not decide what to do about it.

**Decision Layer.** This layer consumes evidence produced by the Analysis Layer and determines whether a trading opportunity is qualified. It weighs evidence, applies confidence thresholds, and produces a qualified trade decision or a documented rejection. It does not touch the terminal, and it does not manage open positions.

**Execution Layer.** This layer takes a qualified decision from the Decision Layer and translates it into orders, respecting risk constraints. It owns order placement, modification, and the mechanics of getting a position into the market correctly. It does not decide whether to trade — only how to execute a decision that has already been made.

**Learning Layer.** This layer observes closed trades and historical outcomes to update statistical parameters — not runtime decisions in real time, but the slower-moving calibration that improves future evidence weighting. Its output feeds back into the Analysis and Decision Layers only through reviewed, versioned configuration, never by silently mutating live behavior mid-session.

**Observability Layer.** This layer makes the system's internal state visible: the Dashboard, the Logging Engine, and the Statistics Engine live here. It is a passive layer. It never influences trading behavior; it only reports on it.

Data flows Platform → Analysis → Decision → Execution, with Observability reading from every layer and Learning reading from closed outcomes to inform future configuration. No layer is permitted to skip past its neighbor; the Execution Layer never reads raw platform ticks directly to make a decision, and the Analysis Layer never places an order.

**Runtime instance scope.** Every running Quantum runtime instance is bound to exactly one trading symbol for the duration of its runtime lifetime, established by the chart/EA context at initialization. The Platform Layer resolves this binding, together with the instance's runtime identity (Strategy ID, Instance ID, Magic Number), once at startup; no layer may change it mid-session. Multiple instruments are supported by running multiple independent Quantum runtime instances rather than by one runtime instance iterating across symbols internally, and multiple independently identified instances may operate on the same symbol simultaneously (for example, parameter or strategy-version variants). Shared implementation does not imply shared runtime state: two instances may run identical compiled code while owning entirely separate Market Data, Analysis, Decision, Risk, Execution, Position Lifecycle, and Statistics state. No core engine shall require another instance's runtime state to produce its own decisions. This principle, and the runtime identity and position-ownership rules that follow from it, are established in full in ADR-001 (Symbol-Scoped Runtime Architecture) and are binding on every engine described in this document.

**Data flow example.** A single cycle through the layers illustrates why the ordering is enforced rather than incidental. A bar closes on the working timeframe. The Platform Layer detects the new-bar event and constructs a fresh snapshot of price and account state. The Analysis Layer engines run against that snapshot: the Market Structure Engine reports a confirmed break of structure, the Liquidity Engine reports a recently swept low, the Session Context Engine reports that the London session has just opened, and the Market Regime Engine reports a trending regime with high confidence. Each of these is published as independent evidence, with no engine aware of what the others concluded. The Decision Layer's Trade Quality Engine reads all four evidence records, applies its configured weights, and produces a qualification verdict — in this case, a qualified long setup with an aggregate confidence above the configured threshold. That verdict, together with its full evidence bundle, is logged before anything else happens. Only then does the Execution Layer receive the qualified decision; the Risk Engine sizes it against current account exposure, and the Execution Engine places the order. The Position Lifecycle Engine takes ownership of the trade from that point forward. At every step, the layer below only ever received what the layer above explicitly published — never a shortcut, and never raw data reinterpreted mid-flight.

---

## 7. Engine Architecture

An engine is the fundamental architectural unit of Project Quantum. Every engine is defined by five properties, and every engine in this system shall have all five explicitly documented before it is considered architecturally complete.

**Purpose.** A single sentence stating what the engine exists to do. If it cannot be stated in one sentence, the engine's responsibility is not yet single.

**Responsibilities.** The specific, enumerable things the engine owns. Responsibilities are exhaustive — anything not listed is explicitly not the engine's job, and if it is currently being done by that engine anyway, that is architectural debt to be corrected.

**Inputs.** The data the engine requires to do its job, and where that data comes from. Inputs shall be explicit parameters or well-defined shared data structures — never ambient global state read implicitly.

**Outputs.** The data the engine produces, in what structure, and who is permitted to consume it. An engine's output is its contract with the rest of the system; changing an output's shape is a breaking change and shall be treated with the same care as changing a public interface in any other engineering discipline.

**Boundaries.** What the engine explicitly does not do, particularly the responsibilities that a naive design would be tempted to fold in. Boundaries are as important as responsibilities, because boundary erosion is how single-responsibility engines quietly become multi-responsibility engines of "just one more thing."

This document deliberately does not describe how any engine is implemented internally. Implementation is a downstream concern that follows from architecture; it is not architecture itself. An engine's internal algorithm may change freely as long as its purpose, responsibilities, inputs, outputs, and boundaries remain intact. If a change to an engine's internals requires changing its purpose or boundaries, that is not an implementation change — it is an architectural change, and it is subject to the Evolution Policy in Section 17.

---

## 8. Engine List

Project Quantum consists of the following fourteen engines. Together they cover the full path from raw market data to an executed, monitored, and statistically evaluated trade.

**Market Regime Engine.** Classifies the current market condition — trending, ranging, or volatile/transitional — using observable price behavior over a defined lookback. Its output is a regime state with an associated confidence, consumed by every downstream engine that needs to weight its own evidence differently depending on regime. It does not decide trades; it characterizes the environment trades will be judged against.

**Market Structure Engine.** Identifies structural price behavior: swing highs and lows, breaks of structure, changes of character, and trend continuation or exhaustion signals. It owns the definition of "structure" for the entire platform so that no other engine invents its own competing definition.

**Liquidity Engine.** Identifies areas where resting orders are likely to cluster — prior highs and lows, equal highs/lows, and liquidity sweeps. It reports where liquidity has been taken and where it likely still rests. It does not interpret this as a trade signal; it reports it as evidence.

**Institutional Zones Engine.** Maps areas of prior institutional interest — order blocks, imbalance/fair value zones, and mitigation states. It owns zone lifecycle: creation, validity, mitigation, and invalidation. Other engines consume zone state; they do not maintain their own copies of it.

**Session Context Engine.** Tracks trading session state (Asian, London, New York, and their overlaps), session-relative price behavior, and time-of-day context. It provides the temporal frame that other engines use to weight evidence appropriately for the current session's typical behavior.

**Trade Quality Engine.** Consumes evidence from the Market Regime, Market Structure, Liquidity, Institutional Zones, and Session Context engines and produces a single qualification verdict: does this opportunity meet the platform's evidentiary bar to be considered tradeable, and with what confidence. This is the primary engine of the Decision Layer.

**Execution Engine.** Converts a qualified decision into terminal-level orders. It owns entry mechanics, order type selection, slippage handling, and the technical correctness of getting into a position as instructed. It does not evaluate whether the trade should be taken — that decision has already been made upstream.

**Risk Engine.** Owns position sizing, maximum exposure rules, and per-trade and instance-level risk limits for its own runtime instance — stop-loss-based sizing, maximum position size, instance/symbol exposure, instance-level daily and drawdown limits, and margin feasibility. No order shall reach the terminal without passing through the Risk Engine's sizing and limit checks. The Risk Engine does not own cross-symbol correlation exposure, portfolio-wide allocation, or account-wide (cross-instance) daily-loss coordination — these are account-level concerns explicitly outside the core symbol-scoped runtime, and may only be introduced through a dedicated future architectural extension and ADR (ADR-001, Sections 14–15).

**Position Lifecycle Engine.** Manages open positions after entry: stop and target adjustment, partial exits, trailing logic, and time-based management rules. It owns everything that happens to a trade between entry and final close, including reconstructing that state from broker-side truth after a restart, filtered by the owning instance's symbol and magic/instance identity (ADR-001, Restart Recovery). It does not decide new entries.

**Statistics Engine.** Records outcomes of closed trades and derives performance metrics — win rate, expectancy, drawdown, evidence-weighted performance by engine and by setup type. It is the platform's evidentiary memory and the primary input to the Learning Layer.

**Dashboard Engine.** Renders current system state to the chart for the operator: active regime, open evidence, current positions, and key statistics. It is read-only with respect to trading logic; it displays state, it never sets it.

**Logging Engine.** Owns structured, leveled logging across every other engine. It provides the audit trail that makes every decision explainable after the fact, and it is the primary tool used to diagnose behavior during both backtesting and live operation.

**Configuration Engine.** Owns all externally adjustable parameters — inputs, presets, and risk settings — validates them at startup, and exposes them to other engines through a single, well-defined access point rather than scattered global inputs.

**Kernel.** The orchestrator. It owns the platform event loop, initializes every other engine in the correct order, drives the flow of data from layer to layer, and enforces that engines communicate only through the channels defined in Section 9. Each Kernel instance is initialized for exactly one trading symbol and owns its instance's runtime identity (Strategy ID, Instance ID, Magic Number), resolved once at startup and immutable thereafter. The Kernel contains no trading logic of its own; its only responsibility is correct sequencing and wiring.

**Engine interdependency summary.** The five Analysis Layer engines — Market Regime, Market Structure, Liquidity, Institutional Zones, and Session Context — depend only on the Platform Layer's snapshot and produce evidence consumed exclusively by the Trade Quality Engine; they do not depend on one another. The Trade Quality Engine is the sole consumer of all five and the sole producer of qualified decisions passed downstream. The Risk Engine and Execution Engine depend only on a qualified decision, never on raw analysis evidence directly — this is what allows the Risk Engine to be tested with synthetic decisions and no market data at all. The Position Lifecycle Engine depends on the Execution Engine's confirmation of a filled order and, thereafter, on fresh Platform Layer snapshots for its own management logic; it does not depend on the original qualifying evidence, since a position's ongoing management is governed by its own rules, not by re-litigating why it was opened. The Statistics Engine depends only on closed-trade records from the Position Lifecycle Engine. The Dashboard, Logging, and Configuration engines are depended upon by every other engine but depend on none of them, which is what makes them safe to read from any layer without violating Section 9's ownership rules.

---

## 9. Engine Communication Rules

Communication between engines is the single highest-risk area for architectural decay in a system like this, because informal shortcuts are always the path of least resistance under deadline pressure. The following rules are therefore treated as strict, not advisory.

**Allowed communication.** An engine may consume data explicitly published by another engine through a defined output structure (see Section 11). An engine may call another engine's public interface functions if — and only if — that call flows downstream according to the layer order in Section 6 (Platform → Analysis → Decision → Execution), or is a read of Observability/Configuration data, which any layer may read.

**Forbidden communication.** An engine shall never reach into another engine's internal variables, private state, or implementation details. An engine shall never call "sideways" across an unrelated engine in the same layer to request a favor outside its own responsibility (for example, the Execution Engine directly querying the Liquidity Engine — that evidence must already have been folded into the Decision Layer's verdict before Execution ever runs). An engine shall never call "upstream" against the layer order — the Analysis Layer shall never query the Execution Layer, and no engine shall query the Position Lifecycle Engine to influence a new-entry decision.

**Ownership.** Every piece of shared data has exactly one owning engine. Only the owning engine may write to it. Every other engine may only read it through the defined output contract. Two engines shall never own overlapping data — if this occurs, it is a sign the engines' boundaries were drawn incorrectly and Section 4.4 has been violated.

**Dependencies.** An engine's dependencies shall be explicit and minimal — the smallest set of upstream outputs it actually needs. Dependencies are declared, not discovered by reading the implementation.

**No circular dependencies.** If Engine A depends on Engine B's output, Engine B shall never depend on Engine A's output, directly or transitively. The Kernel's initialization order is a directed acyclic graph, and it shall remain one. If a genuine two-way relationship seems necessary, the correct fix is almost always a third engine or a lifecycle boundary — as in the case of the Statistics Engine feeding the Learning Layer, which updates Configuration, which the original engines read at the start of the next session, rather than any engine mutating another engine's behavior mid-session.

**No hidden coupling.** Coupling that only exists because of assumed execution order, shared global variables not owned by anyone, or "it happens to work because Engine X always runs before Engine Y" is forbidden. If order matters, the Kernel enforces it explicitly; engines shall not assume it silently.

**A worked anti-pattern.** Consider a plausible but forbidden shortcut: the Position Lifecycle Engine, while managing an open trade, notices that a fresh liquidity sweep would make a good case for tightening the trailing stop, and calls the Liquidity Engine directly to check. This looks harmless — both engines already exist, and the call is easy to write. It is nonetheless a Section 9 violation on two counts: it is a sideways call from the Execution Layer's position-management engine into the Analysis Layer, skipping the Decision Layer entirely, and it creates an undeclared dependency that is not visible anywhere except inside that one function body. The correct design keeps the Position Lifecycle Engine's management rules self-contained, or, if fresh liquidity evidence genuinely needs to inform trade management, routes that evidence through an explicit, documented output that the Kernel passes down — not a direct engine-to-engine call invented to solve one problem quickly.

---

## 10. Event Philosophy

Project Quantum is event-driven where events genuinely simplify the system, and it is deliberately not built around an enterprise event bus, publish-subscribe framework, or message broker. MQL5 already provides the platform's native event model — `OnTick`, `OnTimer`, `OnTradeTransaction`, `OnChartEvent` — and this architecture builds directly on that model rather than layering an abstract event system on top of it.

The Kernel is the single entry point for every terminal event. It receives the event, determines which engines need to react, and drives them in the correct layer order. Engines do not register their own listeners against the terminal directly; they are invoked by the Kernel. This keeps the flow of control traceable — at any point, the call stack shows exactly why an engine is running, rather than requiring a mental model of an implicit subscription graph.

Internally, "events" in Project Quantum are lightweight, meaningful state transitions that matter to more than one engine — a new bar closing, a structural break being confirmed, a position closing, a session changing. These are represented as simple, explicit signals passed through defined output structures and read by the Kernel-driven flow, not as a generalized event bus with arbitrary topics and arbitrary subscribers. An engine's "event" is nothing more than a change in its published output that the Kernel notices and routes onward, exactly as any other piece of that engine's output data would be routed.

This lightweight approach is deliberately chosen because a full publish-subscribe architecture solves problems of scale and decoupling that arise with many independent teams and many services — problems this platform, built by one developer inside one terminal process, does not have. Introducing that machinery here would violate Section 4.12 (Pragmatic Simplicity) and Section 5's prohibition on enterprise infrastructure, while making the flow of control harder, not easier, to explain.

---

## 11. Data Philosophy

Data is the medium through which engines cooperate without coupling to each other's internals, so the rules governing it are foundational.

**Shared objects.** Where engines must share state, that state is represented as a well-defined struct or class instance owned by exactly one engine and exposed read-only to consumers. There is no undocumented global variable used as an implicit communication channel anywhere in the system.

**Snapshots.** Analysis engines operate on a snapshot of market state for the current evaluation cycle, not on a live-mutating reference that could change mid-calculation. A snapshot is taken once per relevant event (typically once per closed bar, or once per tick where tick-level reaction is architecturally required), and every engine consuming that snapshot within the cycle sees the same, frozen view of the world. This is what makes Section 4.1's determinism guarantee enforceable rather than aspirational.

**Evidence.** Evidence is a specific data shape: a claim, a confidence value, and a reference to the source engine and the snapshot it was derived from. Evidence is never a bare boolean or a bare number without this context. "Bullish: true" is not evidence in this architecture; "Market Structure Engine, snapshot #4821, bullish break of structure confirmed, confidence 0.74" is.

**Trade decisions.** A trade decision is a first-class data structure produced by the Decision Layer, carrying the qualifying evidence bundle, the confidence that led to qualification, and the parameters the Execution Layer needs. It is logged in full at the moment it is created, before execution occurs, so that the decision can be reconstructed even if execution subsequently fails or is rejected by the Risk Engine.

**State ownership.** Every mutable piece of state in the system belongs to exactly one engine, as established in Section 9. State ownership is documented alongside the engine's Section 7 definition. Ownership is not transferred at runtime; if responsibility for a piece of data needs to move to a different engine, that is an architectural change subject to Section 17.

**Data immutability where practical.** Once a snapshot, an evidence record, or a trade decision has been created and logged, it is treated as immutable historical fact. Engines do not retroactively edit past evidence or past decisions to reflect new information; new information produces new evidence records referencing the old ones, preserving a complete and honest audit trail. This is a deliberate constraint: a system that can quietly rewrite its own history cannot be trusted to explain itself.

**Conceptual shape, not schema.** This document does not prescribe struct layouts or field names — that is implementation detail. What it prescribes is the conceptual shape every piece of shared data must have: an identifying reference to the snapshot or cycle it belongs to, the producing engine's identity, the substance of the claim, and, where applicable, a confidence value. A snapshot conceptually carries a cycle identifier, the instrument and timeframe it describes, and the price and account state at that instant. An evidence record conceptually carries a reference back to that snapshot, the producing engine's name, the claim itself, and a confidence value. Any engine's output that lacks one of these elements is incomplete, regardless of how it is technically implemented.

---

## 12. Evidence-Based Decision Model

No single engine in Project Quantum has the authority to unilaterally decide that a trade should be taken. This is a foundational design choice, not a stylistic preference, and it exists because single-signal systems are fragile, unexplainable when wrong, and impossible to improve in a targeted way.

**How engines contribute evidence.** Each Analysis Layer engine produces evidence relevant to its domain — structure, liquidity, zones, regime, session — without knowledge of what the other engines are reporting. This independence is deliberate: it prevents engines from being tuned to agree with each other rather than with the market, and it keeps each engine's contribution auditable in isolation.

**Weighted evidence.** The Trade Quality Engine combines evidence from multiple sources using explicit, documented weights. Weights are not arbitrary; they are configuration, owned by the Configuration Engine, informed over time by the Statistics Engine's record of which evidence types have historically correlated with favorable outcomes. Weights can change between sessions through the Learning Layer's calibration process (Section 6); they do not silently drift within a session.

**Confidence.** Every piece of evidence and every aggregate qualification verdict carries a confidence value on a defined scale. Confidence is not a vague feeling encoded as a number — it reflects the historical reliability and current strength of the underlying signal, and its calculation method is documented at the point where it is produced.

**Why no single engine decides trades.** A structure break without liquidity confirmation is weaker evidence than a structure break with it. A liquidity sweep in the wrong session or the wrong regime is weaker evidence than the same sweep in a favorable context. By requiring the Trade Quality Engine to aggregate independent evidence rather than letting any one engine issue an executable signal, Project Quantum ensures that trades reflect convergence of evidence, not the opinion of a single detector — and it ensures that when a trade goes wrong, the postmortem can identify exactly which piece of evidence was weak, misweighted, or absent, rather than shrugging at an unexplainable black box.

This model is what makes the Learning Layer meaningful: because evidence is itemized and attributed per engine, the Statistics Engine can measure the real-world performance of each evidence source independently, and recalibrate its weight rather than throwing away or blindly trusting the whole system.

**A worked qualification example.** Suppose, on a given cycle, the Market Structure Engine reports a bullish break of structure at confidence 0.70, the Liquidity Engine reports a confirmed sell-side liquidity sweep at confidence 0.65, the Session Context Engine reports the London–New York overlap at confidence 1.00 (a factual, not probabilistic, observation), and the Market Regime Engine reports a trending regime at confidence 0.60. The Trade Quality Engine applies its configured weights to each — structure and liquidity weighted most heavily as the platform's historically strongest evidence types, regime and session weighted as context that scales the others rather than standing alone — and produces an aggregate confidence of, say, 0.74. If the configured qualification threshold is 0.65, the setup qualifies, and the full bundle of four evidence records, each with its own confidence and source, is attached to the resulting trade decision. Had the Liquidity Engine instead reported no sweep at all, the aggregate confidence would have fallen below threshold, and the Trade Quality Engine would log a documented rejection carrying the same evidence bundle — because a rejected setup is exactly as important to explain as an accepted one, and the Statistics Engine treats both as data.

---

## 13. Coding Standards

This section states architectural coding philosophy only. It does not define naming conventions, formatting rules, or file layout — those are implementation detail, documented separately from this constitution and free to evolve without amending it.

Code shall be written to be read, not merely to run. Every function's purpose shall be inferable from its name and signature without needing to read its body. Every engine's public interface shall be small: the minimum set of functions required for the Kernel and permitted consumers to use it correctly.

Code shall fail loudly and specifically. Silent fallbacks that mask an unexpected condition are forbidden; if an engine receives data it cannot process, it logs the condition through the Logging Engine and fails in a defined, predictable way rather than guessing.

Code shall avoid hidden control flow. Deeply nested conditionals that encode multiple decisions in a single function are a sign that a function is doing more than one job and should be decomposed, consistent with Section 4.4 applied at the function level, not just the engine level.

Magic numbers are forbidden in decision-relevant logic. A threshold, a weight, a lookback period — anything that shapes a trading decision — is named, owned by the Configuration Engine, and documented with the reasoning behind its default value.

Code shall prefer explicitness over implicit platform behavior. Where MQL5 offers a convenient implicit default, Project Quantum's code states its assumption explicitly rather than relying on the developer (or the AI assistant) to remember what the implicit default was.

Trade-affecting operations shall check their own return values. A call to modify, close, or open a position that is not checked for success is treated as a defect, not an oversight — the Risk Engine and Execution Engine in particular shall never assume a terminal call succeeded without confirming it, because an unconfirmed failure in either engine can leave the account in a state the rest of the system believes is false.

Code shall not rely on busy-waiting or artificial delays to work around ordering problems. If a piece of logic only works because a `Sleep()` call happened to give another part of the system enough time to catch up, the underlying ordering dependency is undeclared, which is itself a Section 9 violation dressed up as a timing issue.

---

## 14. Repository Organization

The repository's folder structure exists to make ownership and layer membership visible at a glance, not to satisfy a generic template. Every folder in the repository corresponds to a real architectural concept defined elsewhere in this document.

Folders are organized first by layer (Platform, Analysis, Decision, Execution, Learning, Observability), and within each layer, by engine. This means a developer — or an AI assistant — can locate any engine's source by knowing only its name and its layer, without needing to search the entire repository.

Separation of concerns is enforced structurally: an Analysis engine's source files live under the Analysis layer's folder and nowhere else. If a file needs to exist in two places, that is a sign its responsibility crosses a layer boundary and needs to be split, not a justification for duplicating the folder structure.

Shared, cross-cutting code — data structures used by multiple engines, common utility functions, the Logging and Configuration engines that every layer depends on — lives in a clearly separated shared area, distinct from any single engine's folder, so it is obvious at a glance that this code is a dependency of the whole system rather than the property of one engine.

Ownership is documented at the folder level: each engine's folder contains, alongside its source, the Section 7 definition for that engine (purpose, responsibilities, inputs, outputs, boundaries) so that the architectural contract travels with the code it governs rather than living only in this top-level document.

Test code mirrors the production structure exactly, folder for folder and engine for engine, so that Section 4.9's testability principle has an obvious, discoverable home for every engine's tests.

---

## 15. AI Collaboration Workflow

Project Quantum is built by one human developer working with multiple AI assistants — ChatGPT, Claude, Codex, and optionally Gemini. This section defines who is responsible for what, so that AI assistance strengthens the architecture instead of eroding it through well-intentioned but uncoordinated suggestions.

**Owner.** The human developer holds final authority over every architectural and implementation decision. The owner is responsible for approving changes to this constitution, resolving disagreements between AI assistants, and ensuring that AI-generated code is actually read and understood before it is merged — not merely accepted because it compiles.

**ChatGPT.** Used primarily for architectural reasoning, design exploration, and drafting or revising documents like this one. When used for code, its output is treated as a proposal subject to the same review as any other AI-generated code.

**Claude.** Used primarily for structured technical writing, careful multi-file reasoning, and implementation work that benefits from close adherence to an existing specification. Claude-generated code is expected to explicitly reference which engine and which Section 7 contract it is implementing.

**Codex.** Used primarily for focused implementation tasks — writing or refactoring a specific engine's internals against an already-approved interface. Codex is not used to make architectural decisions; it implements decisions that have already been made and documented.

**Gemini (optional).** Used opportunistically for secondary review, alternative-perspective checks, or research tasks that benefit from a second model's take, at the owner's discretion.

**Review workflow.** No AI-proposed change — architectural or implementation — is accepted without the owner reviewing it against this document. Any AI-proposed change that would alter an engine's purpose, responsibilities, inputs, outputs, or boundaries as defined in Section 7 is treated as an architectural change, not an implementation change, and is routed through Section 17's Evolution Policy regardless of which assistant proposed it.

**Architecture ownership.** This document is authored and amended by the owner, with AI assistance in drafting and reviewing language — but the decision to adopt a change belongs to the owner alone. No AI assistant has standing authority to modify this constitution unilaterally within a session; every proposed amendment is a suggestion until the owner accepts it.

**Implementation ownership.** Once an engine's architecture is fixed by this document, AI assistants are free to propose and write implementation code within those boundaries. Implementation-level suggestions that stay inside an engine's documented contract do not require a constitutional review — they require only the owner's normal code review.

---

## 16. Architectural Constraints

The following constraints are absolute. They are not guidelines to be weighed against convenience; they are boundaries that no change, however well-intentioned or however urgent, is permitted to cross without first amending this constitution.

* **No circular dependencies** between engines, directly or transitively, as defined in Section 9.
* **No execution logic inside analysis engines.** An Analysis Layer engine shall never place, modify, or close an order. Its job ends at producing evidence.
* **No analysis logic inside execution engines.** The Execution Engine shall never independently reinterpret market structure, liquidity, or regime — it executes what the Decision Layer has already qualified.
* **No learning engine changing runtime decisions mid-session.** The Learning Layer updates configuration for future sessions; it does not reach into a running session and alter live evidence weighting or open-position management.
* **No duplicated responsibilities.** No two engines shall own the same category of decision or the same category of data, as defined in Section 9's ownership rule.
* **No engine bypassing the Risk Engine.** Every order, without exception, passes through Risk Engine sizing and limit checks before reaching the Execution Engine's terminal calls.
* **No hidden global mutable state.** Every piece of mutable state has a documented owner, per Section 11.
* **No assumed position/order isolation.** MetaTrader's position, order, and history APIs are terminal-wide, not scoped to the chart or process an engine happens to run in. No engine shall assume that chart attachment alone limits which positions or orders it sees; every position, order, and history operation shall explicitly filter by the owning instance's symbol and magic/instance identity before acting on the result (ADR-001, Position Ownership).
* **No silent failure.** Every unexpected condition is logged through the Logging Engine at the point it occurs, per Section 13.
* **No architecture change without amendment.** Any change to an engine's Section 7 contract, to the layer model in Section 6, or to the principles in Section 4, requires the process defined in Section 17 before implementation begins.

---

## 17. Evolution Policy

Project Quantum's architecture is expected to evolve. This constitution is not a claim that the current design is final — it is a claim that changes happen deliberately, are documented, and are justified, rather than accumulating as undocumented drift.

**New engine approval.** A new engine may be proposed when an existing engine's responsibilities have grown beyond a single, statable purpose, or when a genuinely new category of evidence or capability is needed that does not belong to any existing engine. A new engine proposal states its Section 7 contract in full — purpose, responsibilities, inputs, outputs, boundaries — before any implementation code is written.

**Feature approval.** A new feature is evaluated first against Section 5's Non-Goals and Section 4.12's Pragmatic Simplicity principle. A feature that can be implemented inside an existing engine's documented boundaries needs no constitutional review. A feature that would require expanding an engine's boundaries requires that expansion to be explicitly justified and recorded as an amendment to that engine's Section 7 contract.

**Deprecation.** An engine or capability is deprecated when it no longer serves the platform's Primary Goal, when its responsibilities have been absorbed by a better-designed replacement, or when the Statistics Engine's evidence shows it consistently fails to contribute value. Deprecation is recorded, not silently deleted — the reasoning is kept so the same dead end is not re-explored later without cause.

**Refactoring.** Refactoring that improves an engine's implementation without changing its Section 7 contract is encouraged and requires no constitutional process. Refactoring that changes an engine's contract is, by definition, an architectural change and follows the same review as a new engine proposal.

**Architecture review.** Before any architectural change is implemented, the owner reviews the proposed change against every principle in Section 4 and every constraint in Section 16. If the change survives that review, this document is updated first, and implementation follows — never the reverse. Documentation precedes implementation, as stated in Section 19.

**Versioning.** Every amendment to this document is recorded with a date and a short rationale, appended to a changelog maintained alongside this file. This document itself is not versioned by rewriting history — prior rationale is kept, not deleted, so that a future amendment does not have to rediscover why a boundary was drawn where it was. A change that only clarifies wording, with no effect on any engine's Section 7 contract, is not required to go through full architecture review, but is still noted in the changelog for continuity.

---

## 18. Definition of Architectural Success

Architecture is successful when the following properties hold, and it is the standard against which every future change is measured.

**Understandable.** A developer — or an AI assistant with access to this document and one engine's source — can explain what that engine does and why, without needing the entire codebase in context.

**Deterministic.** The same market data and configuration produce the same decisions, every time, in backtest and in live operation alike.

**Maintainable.** Adding a reasonable new capability does not require touching engines unrelated to that capability. The cost of a change is proportional to its scope, not to the size of the whole system.

**Reviewable.** Every engine's contract is small enough, and clear enough, that the owner can meaningfully review AI-proposed changes against it rather than rubber-stamping code that compiles.

**Modular.** Any engine can be reimplemented internally, or replaced entirely with a different approach to the same responsibility, without requiring changes anywhere else in the system.

**Reliable.** The system behaves predictably under real market conditions, including conditions not seen during development, because its behavior is governed by explicit rules and explicit evidence rather than untested implicit assumptions.

**Explainable.** Every trade, every rejection, and every position management decision can be reconstructed after the fact from the evidence trail and logs alone, with no need to guess at what the system "must have been thinking."

Architectural success is not measured by feature count, by lines of code, or by how sophisticated the system appears. It is measured by whether these seven properties hold as the system grows.

---

## 19. Governance

Major architectural decisions shall also be recorded as ADRs
(Architectural Decision Records).

SYSTEM_ARCHITECTURE.md defines the constitution.

ADRs define why major decisions were made.

Documentation and code modules shall remain small enough to be fully reviewed by AI assistants within a practical context window.

Large monolithic files should be avoided unless they represent constitutional documents.

Architecture takes precedence over convenience. A shortcut that violates this document is not acceptable merely because it is faster to ship, even under time pressure, even for a single trade idea the owner is eager to test. If a fast experiment is genuinely needed, it is built as an isolated, clearly labeled experimental script outside the production engine structure — never as a compromise smuggled into a production engine.

Documentation precedes implementation. An engine's Section 7 contract, or an amendment to one, is written and reviewed before the corresponding code is written. This is not bureaucracy for its own sake; it is the mechanism that keeps this document truthful. A constitution that describes a system different from the one actually running has failed at its only job.

Architecture changes require justification. Every amendment to this document states, in plain language, what problem the change solves and why the existing architecture could not solve it within its current boundaries. "It would be more convenient" is not sufficient justification on its own; "the existing boundary is actively preventing correct, explainable behavior" is.

The owner is the final authority, and the owner is bound by this document as much as any AI assistant or any piece of code. This constitution exists precisely because good intentions and good memory are not sufficient governance for a system that will run unattended against real capital.

---

## 20. Final Statement

This document, SYSTEM_ARCHITECTURE.md, is hereby established as the architectural constitution of Project Quantum.

It supersedes all prior informal notes, chat-based design discussions, and undocumented conventions. It governs every engine, every layer, and every line of MQL5 code written under the Project Quantum name, regardless of whether that code was written by the owner directly or drafted with the assistance of ChatGPT, Claude, Codex, or Gemini.

Every engine shall have exactly one purpose. Every decision shall be traceable to evidence. Every piece of state shall have exactly one owner. Every change to this architecture shall be documented before it is built. No engine, no feature, and no optimization is exempt from these rules by virtue of urgency, cleverness, or convenience.

Project Quantum is built by one developer, for the long term, to be understood, trusted, and extended for years — not merely to run today. This constitution is the instrument that makes that possible.

**Adopted as the governing architecture of Project Quantum, effective immediately upon replacement of any prior version of this file.**