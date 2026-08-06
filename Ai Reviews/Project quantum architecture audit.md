# PROJECT QUANTUM — ARCHITECTURE AUDIT
### Principal Engineering Review — Pre-Implementation Stage
Reviewer role: Principal Software Engineer / Institutional Code Auditor
Scope reviewed: `MASTER_DESIGN_BIBLE.md`, `SYSTEM_ARCHITECTURE.md`, `PROJECT_GOVERNANCE.md`, `Project Structure.md`, `Architecture.md`, and all 12 module specification prompts.

**A note on scope.** This package contains architecture and specification *prompts* — the intended input to a code-generation process — not implemented MQL5 source. There is no code to run static analysis on yet. That is a genuine advantage: every finding below is a design-level fix, not a refactor. The audit therefore focuses on what the specification documents *commit the future codebase to*, since at >100k LOC, contradictions baked into the constitution get expensive fast.

The architecture and philosophy are respected throughout — no findings here propose new indicators, new strategy logic, or a redesign of the evidence-based/modular philosophy. All findings are software-engineering issues: contradictions between documents, missing interfaces, coupling the documents don't admit to, and scale risks.

---

## EXECUTIVE SUMMARY

The layered philosophy (Evidence → Trade Quality → Execution → Risk → Learning → Dashboard, all through a Data Bus) is sound and worth keeping. The problem is that **the documents don't actually agree with each other about what that pipeline requires**, and the two components everything else depends on — the Data Bus and a common engine interface — are the least specified pieces in the whole package. The highest-priority items:

1. **No multi-symbol/portfolio architecture**, despite "Multi-symbol (Forex + Gold)" being a named project objective and portfolio-correlation risk being an explicit Risk Engine requirement.
2. **Risk and Execution have a circular dependency** as specified — Execution needs Risk's approval before placing an order; Risk's own lifecycle needs to run before the order exists.
3. **The "Evidence Layer" is drawn as independent siblings but isn't** — Liquidity and Zones both require reading Regime/Bias/Session as scoring inputs, with no defined update order or staleness contract.
4. **The Learning Engine is explicitly required to feed Execution** — the exact dependency `SYSTEM_ARCHITECTURE.md`'s own "Forbidden" list bans by name.
5. **No two module specs share the same lifecycle API**, despite Module 12's own acceptance criteria demanding lifecycle consistency across every engine.
6. **The Data Bus — the single channel through which 100% of inter-module data flows — has no specification at all.**

None of these require touching the trading logic or the layered philosophy. They require about a day of documentation work before Module 02 code generation starts, versus months of rework if caught at 60k lines.

---

## PART A — FOUNDATIONAL CONTRADICTIONS

These are places where two of your own documents disagree, or a module's own body contradicts its own integration section.

### F1. No architecture for multi-symbol / portfolio operation
**Evidence:** `MASTER_DESIGN_BIBLE.md` lists "Multi-symbol (Forex + Gold)" as an objective. `Prompt 09` requires "Maximum symbol risk," "Maximum correlated exposure," "Currency exposure," and "Net directional exposure" under Portfolio Risk. Nothing in any of the 12 prompts, or in `SYSTEM_ARCHITECTURE.md`, says whether an engine is instantiated once per symbol or once globally with a symbol parameter.

**Why it matters:** This isn't a detail — it determines the shape of nearly everything else. In real MT5 deployment, an EA is attached per-chart/per-symbol; there is no built-in shared memory between chart instances except `GlobalVariables` or files. If each symbol gets its own isolated Regime/Bias/Liquidity/Risk engine instances (the natural MT5 pattern), then "maximum correlated exposure across symbols" is *structurally impossible* to compute inside any single instance — you'd need a separate cross-instance registry that nothing in the spec describes. If instead one master instance is meant to loop over symbols internally, that's a fundamentally different Kernel, Data Bus, and threading model than anything described, and the Strategy Tester's default single-symbol backtest mode won't validate it correctly either.

**Long-term impact:** This is the kind of gap that doesn't surface until Module 09 (Risk) is actually being built — at which point the Kernel, Data Bus, and every "per-symbol" engine already exist and were built without symbol-scoping in mind. Retrofitting portfolio awareness onto ten already-built single-symbol engines is a rewrite, not a patch.

**Fix:** Before generating any engine code, write an explicit "Multi-Symbol & Portfolio Architecture" addendum to `SYSTEM_ARCHITECTURE.md` that answers: (a) is there one engine instance per symbol, or a symbol-keyed data structure inside a shared instance? (b) how does cross-chart/cross-symbol state get shared in live trading (GlobalVariables, file-based IPC, or a designated "master" chart)? (c) how is portfolio correlation validated in the Strategy Tester given its single-symbol-per-run default? Every Data Bus struct should then carry an explicit `symbol` field from day one, even if v1 only ever runs one symbol at a time.

**Severity: CRITICAL**

---

### F2. Circular dependency between Execution and Risk
**Evidence:** `Prompt 08` (Execution): "Only continue if... Execution permitted by Risk Engine" and lists Risk Engine as a consumed input. `Prompt 09` (Risk): its own lifecycle diagram is "Pre-Trade Validation → **Position Sizing** → Protective Order Placement → Active Monitoring..." — i.e., Risk's own body says sizing/SL/TP happen *before* the order exists — yet its Integration section says it "Consume[s] outputs from **Entry & Execution Engine**." `SYSTEM_ARCHITECTURE.md`'s allowed dependency chain is one-directional: `Execution → Risk`.

**Why it matters:** You cannot place a market/limit order without a lot size and (for most stop models) a stop-loss price — both of which, per Prompt 09, are Risk's job. But Prompt 08 says Execution can't proceed without Risk's pre-approval. That's Execution needing Risk before the order, and Risk needing the order's ticket to manage afterward — two genuinely different responsibilities wearing one module's name.

**Long-term impact:** As specified, `Execution.mqh` and `Risk.mqh` will need to `#include` each other's types, which is exactly the circular-include problem MQL5 (like C++) makes painful. Worse, whoever implements this will resolve the ambiguity ad hoc, and it'll likely differ from whatever a second engineer assumed six months later.

**Fix:** Split "Risk Engine" into two explicitly separate interfaces with different lifecycle phases, matching the split that's already implicit in Prompt 09's own two-part lifecycle diagram:
- `IPreTradeRiskValidator` — a stateless/pure function: `(TQI result, account state, proposed stop distance) → (approved, lotSize, stopPrice, targetPrice)`. Execution calls this *before* placing the order.
- `IPositionLifecycleManager` — receives the filled ticket *after* execution and owns trailing, break-even, exits, and Position Health scoring.

This also makes position sizing trivially unit-testable (pure function, no broker state), which the project's own Testing Policy asks for.

**Severity: CRITICAL**

---

### F3. Trade Quality Index needs Risk/Reward before Risk Engine has run
**Evidence:** `Prompt 07`'s Layer 3 ("Execution Readiness") explicitly lists inputs including "RR" and "Risk / Reward." But per `SYSTEM_ARCHITECTURE.md`'s pipeline, TQI sits *before* both Execution and Risk. R:R requires a stop-loss and target, which Prompt 09 assigns to the Risk Engine, two stages downstream.

**Why it matters:** TQI cannot honestly score a real R:R without knowing where a stop would go — but you don't want the (expensive) authoritative Risk Engine sizing calculation to run for every setup, including ones TQI will reject. Real systems resolve this with two deliberately different numbers: a cheap, provisional R:R estimate inside TQI (e.g., nearest invalidation level vs. nearest opposing liquidity), and the authoritative R:R computed later by Risk once a trade is actually being sized. If this distinction isn't named and documented, you get two components both quietly computing "the R:R" with no shared definition — Prompt 12's own Integration Review explicitly asks reviewers to check for "no duplicated logic, no duplicated calculations," but nothing today would catch this one because it's not framed as a duplicate — it's two different fields with the same name in two different structs.

**Long-term impact:** When the two numbers diverge (they will), nobody will know which is authoritative, and "why did TQI say 91 but the trade only opened at 1.4R" becomes an unanswerable question in an "explainability first" system — directly undermining the stated Explainability principle.

**Fix:** Rename and document explicitly: `TradeQualityAnalysis.estimatedRR` (cheap, structure/liquidity-based, computed entirely from Evidence-layer data TQI already has) vs. `PositionAnalysis.actualRR` (authoritative, computed once by Risk at sizing time). State in the Foundation doc that these are intentionally different numbers serving different purposes.

**Severity: CRITICAL**

---

### F4. The "Evidence Layer" isn't actually a flat layer of independent siblings
**Evidence:** `Architecture.md`'s top-level diagram draws Regime, Bias, Structure, Liquidity, Institutional Zones, Session, Volatility, and Execution as one undifferentiated box with no internal arrows. But `Prompt 04` (Liquidity) lists "Structure alignment" and "HTF Bias alignment" as liquidity-scoring factors, and `Prompt 05` (Zones) lists "Alignment with HTF Bias," "Alignment with Liquidity," and "Alignment with Market Regime" as inputs to Order Block quality — while each module's own SRP section insists it's "completely independent" from the others.

**Why it matters:** Reading another engine's *published output* as an input is architecturally fine — that's what a Data Bus is for. The actual gap is that nowhere is there a defined execution order for engines within a single tick, and nowhere is there a contract for what a downstream engine gets if it reads before an upstream engine has published this tick's result: last bar's stale value? A blocking wait? Undefined behavior? Given determinism ("identical results for identical historical data") is a stated top-level value, an unspecified intra-layer read order is a real determinism risk, not a style nitpick — backtest and live tick delivery can process near-simultaneous updates in different orders, which is exactly the kind of divergence that shows up as an unreproducible bug years later.

**Long-term impact:** Independently generated module code (11 separate prompts, likely 11 separate generation passes) is very likely to make inconsistent assumptions about read freshness, since nothing forces consistency.

**Fix:** Split "Evidence Layer" into two explicit, named tiers in `SYSTEM_ARCHITECTURE.md`: **Tier 1 (Context Providers)** — Regime, HTF Bias/Structure, Session, Volatility — genuinely order-independent. **Tier 2 (Setup Evaluators)** — Liquidity, Institutional Zones — explicitly documented as consuming Tier 1's *current-tick* published output. State the Data Bus's ordering guarantee in writing: e.g., "engines update in a fixed topological order once per bar; a Tier 2 read of a Tier 1 value always reflects this tick's computation, never a prior one."

**Severity: CRITICAL**

---

### F5. Learning Engine is required to feed Execution — which the constitution explicitly forbids
**Evidence:** `SYSTEM_ARCHITECTURE.md`'s Forbidden dependency list names, verbatim: `Learning ↓ Trade Execution`. `Prompt 10`'s Integration section requires: "Expose calibrated parameters to Trade Quality Index, Risk Engine, **Execution Engine**."

**Why it matters:** This is a direct, checkable, sentence-level contradiction between the constitution and a module spec — not an inference. It's also the easiest one on this list to demonstrate is real, which matters if you're using this list to prioritize what gets fixed first.

**Long-term impact:** If left alone, this is a coin flip: whoever implements Module 10 either follows the constitution (Learning can't reach Execution, breaking the requirement to expose calibrated parameters there) or follows Prompt 10 (violating the constitution's forbidden list, silently). Either way, one of your own governing documents is being ignored, and nothing catches it because they were never checked against each other.

**Fix:** The feedback loop itself is reasonable — adaptive systems should feed back into decisions. What's missing is that it needs to be an *explicitly allowed exception*, not an accidental violation. Update the Forbidden list to read something like: `Learning → Execution (direct logic) — forbidden; Learning → Execution (calibrated weight values only, applied at the next Update() cycle, never mid-decision) — allowed`. Then Prompt 10's requirement and the constitution agree, and the distinction between "Learning changes behavior" (forbidden — would make the system a black box) and "Learning changes a documented, logged, bounded parameter that Execution reads" (fine — this is literally what "Weight Calibration... within user-defined safety bounds" already describes) is written down instead of implicit.

**Severity: CRITICAL**

---

## PART B — MISSING INTERFACES

### F6. No common engine lifecycle interface — every module's own API contradicts it
**Evidence:** `SYSTEM_ARCHITECTURE.md`'s Module Lifecycle is nine stages: `Initialize() → LoadConfiguration() → Warmup() → Validate() → Update() → Analyze() → Publish() → Reset() → Shutdown()`. Every single module prompt's own "API" section lists a different, shorter subset. Regime Engine (Prompt 02): `Initialize, Update, Analyze, GetCurrentRegime, GetConfidence, GetAnalysis, Reset` — no `LoadConfiguration`, `Warmup`, `Validate`, `Publish`, or `Shutdown`. Execution Engine (Prompt 08): `Initialize, Update, ApproveExecution, DetectTrigger, ConfirmEntry, ValidateBroker, PlaceOrder, CancelExecution, GetExecutionAnalysis, Reset` — no `Analyze()` at all. `Prompt 12`'s own Consistency Review explicitly asks reviewers to confirm every engine follows `Initialize(), Update(), Analyze(), GetAnalysis(), Reset()` — a checklist that, as currently written, **none of the ten modules would pass**.

**Why it matters:** The Kernel's entire justification for existing is to "orchestrate modules" generically without knowing anything about trading. That's only possible if every module honors one interface it can call polymorphically. Right now there isn't one — there are ten similar-but-different ones.

**Long-term impact:** Without a shared interface, the Kernel can't be written generically; it will need per-engine special-case calling code, which defeats the stated purpose of having a Kernel at all, and every new module added later (the spec explicitly plans for more) makes this worse, not better.

**Fix:** Define one abstract MQL5 base class before generating further module code — MQL5 classes (unlike structs) support virtual functions, so this is directly implementable:
```
class IQuantumEngine
{
public:
   virtual bool Initialize(...)       = 0;
   virtual bool LoadConfiguration(...) = 0;
   virtual bool Warmup(...)           = 0;
   virtual bool Validate()            = 0;
   virtual void Update()              = 0;
   virtual void Analyze()             = 0;
   virtual void Publish()             = 0;
   virtual void Reset()               = 0;
   virtual void Shutdown()            = 0;
};
```
Every engine inherits from it. Module-specific methods (`DetectTrigger()`, `PlaceOrder()`, etc.) are additive, not substitutes for the common nine. This is the cheapest fix in this entire report relative to its payoff — a few hours now versus a Kernel that can never be generic.

**Severity: CRITICAL**

---

### F7. The Data Bus — the single point 100% of inter-module data flows through — has no specification
**Evidence:** `SYSTEM_ARCHITECTURE.md` states "Modules never communicate directly. All communication occurs through the Quantum Data Bus," and shows it in the layer diagram. None of the 12 prompts is *about* the Data Bus. Its interface, ownership model, and publish/subscribe contract are never defined anywhere in the package.

**Why it matters:** This is the most structurally important piece of plumbing in the whole system, and it's also the one component every other component transitively depends on — and it's the least specified thing here. Given MQL5 has no generics over heterogeneous types and struct polymorphism doesn't work (see F8), the natural implementation path is one singleton class with a `Get`/`Set` pair per engine's result struct — `GetRegime()/SetRegime()`, `GetLiquidity()/SetLiquidity()`, ×10. That satisfies "no direct module-to-module coupling" literally, but it doesn't reduce total coupling — it concentrates all of it into one class that every other file in the project depends on.

**Long-term impact:** At >100k LOC, this becomes the most frequently touched, most merge-conflicted file in the repository, and because MQL5 has no forward-declare-only interface mechanism as clean as C#'s, it's likely to become a hard compile-time dependency that forces wide recompilation on any change — and it makes the "isolated unit tests" requirement (stated in the Testing Policy) hard to satisfy, since mocking "the entire bus" to test one engine is much harder than mocking the one or two channels that engine actually needs.

**Fix:** Write a dedicated Data Bus / Event Scheduler specification before generating more engine code. Use a per-topic publish/subscribe pattern — one small, independently mockable class per data type (`CRegimeChannel`, `CLiquidityChannel`, etc.) — rather than a single monolithic bus class, so each engine depends only on the one or two channels it actually reads, restoring the low-coupling property the architecture claims. Define the topic ordering/freshness guarantee here too (this is the same document that should resolve F4).

**Severity: CRITICAL**

---

### F8. The suggested `EngineResult` struct-inheritance pattern can't deliver the polymorphism it implies
**Evidence:** Prompt 02's closing recommendation proposes `struct RegimeResult : EngineResult { ... }`, `struct LiquidityResult : EngineResult { ... }`, etc., clearly intending a common base type that generic code (Dashboard, Learning's "Engine Analytics — measure effectiveness of... Average confidence, Average contribution" across all engines) can iterate over polymorphically.

**Why it matters:** MQL5 structs support simple field inheritance (this part compiles fine), but structs cannot declare virtual functions and have no vtable — there is no runtime polymorphism through a base-struct reference or array. Any code that tries to hold a generic `EngineResult` collection and dispatch behavior based on the actual derived type will either silently see only the base fields (a "slicing" bug, not a compile error) or require manual type discrimination. This is a real, specific MQL5 language constraint, not a style preference — and Prompt 11's "Engine Analytics" feature genuinely needs this kind of generic cross-engine iteration to work.

**Long-term impact:** If this isn't decided now, whoever builds the Dashboard/Learning modules discovers the limitation mid-implementation and improvises a fix under time pressure — usually a worse one than a decision made calmly up front.

**Fix:** Pick one pattern explicitly in the Foundation document and apply it consistently across all ten modules: either (a) engine results are lightweight **classes**, not structs, with a common abstract base exposing `virtual double GetConfidence()`, `virtual bool IsValid()`, `virtual datetime GetTimestamp()` — used wherever generic aggregation is needed — or (b) keep POD structs everywhere and add a small `EngineID` enum plus a manually maintained dispatcher for the handful of places (Dashboard aggregation, Decision Trace logging) that need to treat "any engine's result" generically. Either is fine; leaving it undecided across 11 independent generation passes is not.

**Severity: IMPORTANT**

---

### F9. The 12-event pub/sub system is defined once and never used again
**Evidence:** `SYSTEM_ARCHITECTURE.md` names twelve events (`OnMarketRegimeChange`, `OnTradeApproved`, `OnLearningUpdate`, etc.) and states "Every engine subscribes only to events it requires. No polling between modules." Not one of the ten module-level prompts references `Subscribe()`, `OnEvent()`, or any of these twelve event names in its own API section — every module's API is instead a synchronous `Update()`/`Analyze()`/`GetAnalysis()` shape, which is a polling pattern by construction (the Kernel calling `Update()` on every registered module every tick/bar *is* polling, just centralized).

**Why it matters:** Either the event system is real and every module spec is missing its subscription methods, or the event system was aspirational and the real design is centralized polling through the Kernel — and if it's the latter, the "No polling between modules" claim in the constitution is inaccurate to what's actually being built.

**Long-term impact:** Small now, but it's exactly the kind of "documentation says one thing, code does another" drift that erodes trust in the architecture docs over time — and this project's whole premise is that the docs are the source of truth developers (and AI contributors) follow.

**Fix:** Decide honestly which model you want. If synchronous `Update()`-per-cycle is genuinely fine (it likely is, given MQL5's tick-driven execution model doesn't need true async pub/sub the way a distributed system would), remove or rescope the event list to describe *notifications the Dashboard/Logger can hook into for observability*, not a mechanism engines use to talk to each other. If real event-driven dispatch is wanted, add `Subscribe(ENUM_QUANTUM_EVENT)` to the common interface from F6 and reference it in each module's API section.

**Severity: IMPORTANT**

---

### F10. No shared configuration-loading/validation interface
**Evidence:** Every module prompt independently states "every threshold must be configurable" and lists 8–15+ parameters, but no shared config-loading, parsing, or validation pattern is specified anywhere.

**Why it matters:** `PROJECT_GOVERNANCE.md`'s own Configuration Policy requires every parameter to document "Description, Default value, Valid range, Reason for existence" — that's real validation logic (range checks, defaults, error messages), and without a shared interface, ten independently generated modules will each hand-roll their own version of it, with ten different error-handling styles, directly conflicting with the Error Handling Policy's demand for centralized, categorized error reporting.

**Long-term impact:** Config validation bugs (an out-of-range threshold silently accepted, or two modules disagreeing on what "invalid" looks like) are exactly the class of bug that's cheap to prevent structurally and expensive to hunt down individually across ten modules later.

**Fix:** Add a small `IConfigSection` interface (or a shared `ValidateRange(value, min, max, paramName)` utility in `Core/Utilities.mqh`) that every module's `LoadConfiguration()` (from F6) is required to route through, so invalid-config errors are reported through one consistent path (`CONFIG` category, per the Error Handling Policy) instead of ten bespoke ones.

**Severity: IMPORTANT**

---

## PART C — SCALABILITY & PERFORMANCE

### F11. No enforced shared-cache discipline across timeframe-heavy engines
**Evidence:** HTF Bias/Structure (Prompt 03) analyzes 6 timeframes with full swing/BOS/CHOCH/impulse detection on each. Liquidity (Prompt 04) tracks 30+ liquidity types across 7 timeframes plus clustering plus a "Liquidity Graph." Institutional Zones (Prompt 05) does Order Block/FVG/BPR detection across 7 timeframes plus a cross-referencing "Interaction Matrix." All three state "designed for millions of backtest ticks... incremental updates... no full rescans every tick" as a goal, but none specify the actual invalidation rule (e.g., "only recompute a timeframe's structure on that timeframe's new-bar event"), and — critically — nothing in any prompt *forbids* an engine from calling `CopyRates`/`iATR` directly instead of going through the shared `CandleCache`/`ATRCache` modules listed in `Project Structure.md`.

**Why it matters:** At least four engines need the same OHLC data across the same set of timeframes. If each of eleven independently generated modules is free to fetch its own history, you get the same candle data copied redundantly on every tick by several engines — exactly the CPU-usage risk the Performance Policy exists to prevent, and the single most likely reason the platform would miss its own "millions of ticks" performance target.

**Long-term impact:** This class of bug doesn't show up in a 6-month backtest of one symbol — it shows up during multi-year, multi-symbol optimization runs, which is precisely when institutional users need it to be fast.

**Fix:** Add a hard rule to the Foundation document: *no engine may call `CopyRates`, `CopyClose`, `iATR`, or any other direct MT5 history/indicator function; all such access is exclusive to `Data/CandleCache.mqh`, `Data/ATRCache.mqh`, and `Data/VolumeCache.mqh`.* Add a centralized `IsNewBar(ENUM_TIMEFRAMES)` gate in the cache layer that every timeframe-dependent engine is required to check before recomputing — implemented once, not reinvented per engine.

**Severity: CRITICAL (for stated performance targets)**

---

### F12. Configuration surface area will break the MT5 Strategy Tester's optimizer
**Evidence:** Summing the explicitly named configurable parameters across the ten module prompts — including per-type enable/disable toggles across 30+ liquidity types and 20+ zone types — conservatively totals 150–250+ user-facing parameters.

**Why it matters:** MQL5's `input` parameters populate both the Expert Properties dialog and the Strategy Tester's optimizer's candidate dimension list. Past roughly a few dozen inputs, the dialog becomes unwieldy and brute-force/genetic optimization becomes computationally infeasible — directly undermining the "support optimization runs efficiently" requirement stated in multiple prompts (e.g., Liquidity Engine's Performance section).

**Long-term impact:** This isn't a correctness bug; it's a "the tool nobody can actually use" bug, and it's specific to MQL5's tooling in a way generic software-engineering advice wouldn't catch.

**Fix:** `PROJECT_GOVERNANCE.md`'s own Configuration Policy already says configurable values belong in `Config/` — enforce that literally. Move the bulk of sub-thresholds and per-type toggles into a structured config file (loaded at `Initialize()`), and expose only a curated ~15–20 "high-value" parameters as actual `input` fields intended for Tester optimization. Tag every parameter in documentation as either "Optimize" or "Configure-once" — that distinction doesn't exist today and needs to.

**Severity: IMPORTANT**

---

### F13. Decision Replay / full audit trail has no retention bound
**Evidence:** Prompt 11's "Decision Replay Engine" records a timestamped entry for every regime/bias/liquidity/zone/TQI/execution/risk update. No ring-buffer, retention window, or disk-paging strategy is mentioned anywhere.

**Why it matters:** Across millions of backtest ticks over years of multi-symbol M15 history, an unbounded per-update log directly conflicts with the project's own Memory Policy ("avoid unnecessary allocations... monitor memory growth") and the Release Requirement of "no memory leaks."

**Long-term impact:** This is exactly the kind of feature that works beautifully in a demo (one short backtest) and then OOMs or grinds to a crawl the first time someone runs a five-year, multi-symbol optimization pass — the primary use case the platform is explicitly designed for.

**Fix:** Define a two-tier retention policy: full per-tick trace kept in memory only for currently-open positions plus the last N closed trades (configurable); anything older is flushed to a rotated file in `Files/`, and "Replay" reads from disk for anything outside the in-memory window.

**Severity: IMPORTANT**

---

### F14. Naive dynamic-array growth pattern risk across every "tracked object list"
**Evidence:** Liquidity levels, institutional zones, swings, CHOCH events, and trade records are all described as growing lists with a "maximum stored" cap, but no prompt specifies the underlying storage strategy.

**Why it matters:** The common MQL5 anti-pattern is calling `ArrayResize()` once per new item — each call is a potential reallocation/copy, and at "millions of ticks" scale with dozens of concurrently tracked objects across multiple engines, this is a well-known, measurable CPU cost.

**Long-term impact:** Individually invisible; cumulatively, across five-plus engines all doing this independently, a meaningful and hard-to-profile-after-the-fact drag on backtest/optimization speed.

**Fix:** Since every one of these structures already has a stated "maximum stored" cap, use fixed-capacity circular buffers sized to that cap from the start, rather than unbounded dynamic arrays with ad hoc pruning. This is a natural fit for a requirement that already exists — it just needs to be named as an implementation requirement, not left as an incidental side effect of the cap.

**Severity: IMPORTANT**

---

## PART D — MAINTAINABILITY & TECHNICAL DEBT

### F15. Duplicate historical-statistics logic: Session "Personality Model" vs. Learning Engine
**Evidence:** Prompt 06's closing enhancement proposes a "Session Personality Model" that maintains its own rolling win-rate/sweep-frequency/mean-reversion statistics per session. Prompt 10's Learning Engine already lists "Session" as one of its Segment Analysis dimensions, computing the same kind of rolling statistics.

**Why it matters:** Two independent rolling-window/decay implementations computing conceptually the same numbers will drift out of sync the moment their decay-rate configs differ even slightly — "Session Engine says 73% sweep frequency for London, Learning Engine says 76%" is a quiet, hard-to-notice credibility problem in a platform whose whole premise is explainability. Prompt 12's own Integration Review explicitly asks for "no duplicated logic, no duplicated calculations" — this is exactly that.

**Long-term impact:** Debugging "why do these two numbers disagree" months later, across two modules that were built by two different generation passes with no shared test.

**Fix:** Session Engine should own only real-time/rules-based session identity and static definitions (open/close times, kill-zone windows). All historical performance statistics belong exclusively in the Learning Engine, consumed by Session Engine or the Dashboard as a read-only report.

**Severity: IMPORTANT**

---

### F16. Duplicate/competing evidence-fusion logic
**Evidence:** Prompt 05's "Institutional Zone Interaction Matrix" enhancement produces cross-engine narrative synthesis ("current price sits inside a high-quality H4 demand zone, reinforced by an unfilled FVG... aligned with a trending bullish regime") — which is precisely what Prompt 07 charters TQI to own exclusively ("No engine should duplicate TQI logic"). Separately, Prompt 07's own body defines a four-layer weighted-hierarchy fusion model, while its closing enhancement proposes a *different* Bayesian sequential-posterior-update model — two mathematically distinct aggregation approaches for the same output, with no reconciliation between them.

**Why it matters:** Fusion logic is the most trust-critical calculation in the entire platform — it's the thing that decides whether a trade happens. Having it defined in two places (Zones + TQI) or two ways (weighted hierarchy + Bayesian) within the same document set means the eventual implementation will pick one arbitrarily, and the rejected approach's assumptions may linger half-implemented in the module that didn't "win."

**Long-term impact:** This is the single most consequential piece of business logic to have ambiguous — get it wrong and every downstream trade-quality claim in the Dashboard and Learning Engine inherits the ambiguity.

**Fix:** Strike the Zones "Interaction Matrix" narrative-synthesis feature; keep Zones' output as the well-typed component scores it already specifies (`orderBlockScore`, `fvgScore`, `premiumDiscountScore`, etc.) and let TQI be the *only* place that performs cross-engine synthesis, textual or numeric. For the fusion-model question, pick one of {weighted hierarchy, Bayesian posterior} as the actual v1 algorithm and demote the other to a documented "future research direction" — don't let both live in the same spec as if they're both current requirements.

**Severity: IMPORTANT**

---

### F17. Object lifetime mismatch: pruned evidence objects vs. long-held position references
**Evidence:** Liquidity/Zones both specify a "Maximum stored levels/zones" cap with an aging/pruning model. Prompt 09's "Position Health Engine" enhancement requires continuously re-checking, for every *open* position, whether the specific zone/liquidity object the trade was scored against is "still valid" and "still favorable" — implying that object needs to remain resolvable for as long as the position stays open, which per the HTF timeframes involved could be days.

**Why it matters:** MQL5 has no garbage collector for raw pointers into dynamically managed arrays. If a Liquidity/Zone array prunes old entries (shifting or reusing array slots) while a Risk-managed position still holds a reference into that array, you have a real dangling-reference/wrong-object-read bug class, not a hypothetical one — this exact pattern (array compaction invalidating stored indices/pointers) is one of the most common sources of subtle, intermittent MQL5 crashes in mature EAs.

**Long-term impact:** Bugs in this category are typically invisible in short backtests and only appear in long-running live sessions with many concurrent open positions — the worst possible time to discover them.

**Fix:** Decide and document ownership explicitly. Recommended: Risk/Position objects **snapshot** the small set of scalar fields they need at entry time (quality score, zone type, price boundaries) rather than holding a live reference to the mutable object — this makes pruning always safe. If genuine live re-evaluation against the *current* state of that exact object is wanted, it must be explicitly pinned/excluded from pruning until the position closes, and that pinning mechanism needs its own spec.

**Severity: IMPORTANT**

---

## PART E — DETERMINISM & TESTABILITY

### F18. Determinism becomes path-dependent once Learning is added, but isn't documented as such
**Evidence:** `SYSTEM_ARCHITECTURE.md`: "The platform must always produce identical results for identical historical data. No randomness. No hidden state." Prompt 10's Learning Engine adjusts TQI evidence weights based on rolling/decayed trade history *as the run progresses*, and those adjusted weights feed back into TQI/Risk/Execution.

**Why it matters:** This combination means "identical historical data" is not, by itself, sufficient for identical results — you also need identical *processing history* (same start date, same warm-up length, same trade sequence), because the learned weights at any point T depend on everything that happened before T. That's a legitimate, common pattern in adaptive systems — but it's a materially different determinism guarantee than "same OHLC window, any start point, same answer," and nothing in the docs distinguishes the two.

**Long-term impact:** A walk-forward test starting mid-history, or a live restart partway through a trading week, will not reproduce what a full-history backtest over the same window would have shown — and because this isn't documented as expected behavior, it will read as a bug report ("backtest and live diverged") rather than a known, designed-for property, wasting debugging time on something that isn't actually broken.

**Fix:** Explicitly scope the Determinism section: guarantee determinism for identical `(start_date, historical_data, configuration, learning_state)` tuples — full-history replay determinism — and state plainly that partial-window or mid-history restarts are not expected to reproduce identical results *unless* Learning state is checkpointed. Then make Learning-state persistence (save on `Shutdown()`, restore on `Initialize()`) an explicit lifecycle requirement — it's currently absent from the Module Lifecycle despite every other piece of state in the system having an explicit ownership/persistence story.

**Severity: IMPORTANT**

---

## PART F — ENTERPRISE-GRADE RECOMMENDATIONS (LOWER-COST, HIGH-LEVERAGE)

### F19. Shared bounded-history utility
At least five modules (Swing history, Liquidity levels, Institutional Zones, CHOCH events, Trade records) need the same "fixed-capacity, append-and-prune" data structure. Hand-rolling this five times independently is where off-by-one pruning bugs live. Add a single templated `CRingBuffer<T>` (or macro-generated equivalent, given MQL5 template support) to `Core/Utilities.mqh` and require every module to use it instead of reimplementing bounded-array bookkeeping. **Nice-to-have, but high-leverage** given how many modules need exactly this pattern.

### F20. Centralized `EnumToString()` helpers
Every module's Logging examples print enum values as readable strings (`TRENDING_BULL`, `Liquidity Sweep Reversal`, etc.). Left unaddressed, ten modules will each hand-write their own `switch`-based string conversion. Centralize these in `Core/Utilities.mqh` alongside the enums themselves. **Nice-to-have.**

### F21. `schemaVersion` fields on persisted structs
`SYSTEM_ARCHITECTURE.md` requires "Compatible Kernel Version" and states breaking changes need "Version increment... Migration notes," but nothing describes what that looks like concretely for MQL5, which has no reflection or safe runtime deserialization of arbitrary old struct layouts. This matters most for Prompt 10's persisted trade-history database — the one artifact institutional users will most care about not losing across a multi-year sequence of upgrades. Add an explicit `int schemaVersion` field to every struct that gets written to disk (not just in-memory Data Bus structs), and document a field-by-field migration pattern for the trade-history file format specifically. **Nice-to-have now, important later — cheap to add today, expensive to retrofit onto years of accumulated trade history files.**

### F22. Warmup-cost budgeting
HTF Bias, Liquidity, and Zones all need full historical reconstruction up to Monthly/Weekly timeframes during `Warmup()`. Nothing bounds how expensive this is allowed to be, and Prompt 12's own robustness tests explicitly include "Restart recovery," "Platform restart," and "Chart refresh" — all of which would trigger a full warmup. Recommend either persisting incremental state to disk across reinitializations (so `OnInit` recomputes only the delta since last shutdown) or an explicit warmup time budget with staged/background loading. **Nice-to-have,** but relevant to the explicit reattach/restart robustness tests already required.

---

## PRIORITY MATRIX

| # | Finding | Category | Severity |
|---|---|---|---|
| F1 | No multi-symbol/portfolio architecture | Foundational | **Critical** |
| F2 | Execution ↔ Risk circular dependency | Foundational | **Critical** |
| F3 | TQI needs R:R before Risk has run | Foundational | **Critical** |
| F4 | Evidence layer's hidden intra-layer coupling | Foundational | **Critical** |
| F5 | Learning → Execution violates constitution's own ban | Foundational | **Critical** |
| F6 | No common engine lifecycle interface | Missing Interface | **Critical** |
| F7 | Data Bus unspecified | Missing Interface | **Critical** |
| F11 | No shared-cache discipline across timeframe engines | Performance | **Critical** |
| F8 | `EngineResult` struct-inheritance can't give polymorphism | Missing Interface | Important |
| F9 | 12-event pub/sub defined once, never used | Missing Interface | Important |
| F10 | No shared config-validation interface | Missing Interface | Important |
| F12 | Config surface breaks Tester optimizer | Performance | Important |
| F13 | Decision Replay has no retention bound | Performance/Memory | Important |
| F14 | Unbounded array-growth pattern risk | Performance/Memory | Important |
| F15 | Duplicate stats: Session vs. Learning | Tech Debt | Important |
| F16 | Duplicate/competing fusion logic | Tech Debt | Important |
| F17 | Evidence-object lifetime vs. open-position references | Tech Debt | Important |
| F18 | Determinism is path-dependent, undocumented | Determinism | Important |
| F19 | Shared ring-buffer utility | Enterprise | Nice-to-have |
| F20 | Centralized `EnumToString()` | Enterprise | Nice-to-have |
| F21 | `schemaVersion` on persisted structs | Enterprise | Nice-to-have |
| F22 | Warmup-cost budgeting | Enterprise | Nice-to-have |

## SUGGESTED REMEDIATION ORDER

All of F1–F11 are documentation fixes to the existing five top-level docs and Prompt 01/07/08/09/10 — none require touching code that doesn't exist yet, and all are cheaper to resolve before Module 02 generation starts than after:

1. Resolve F6 (common lifecycle interface) and F7 (Data Bus spec) first — every other module's generation depends on both existing.
2. Resolve F1 (multi-symbol) and F2 (Risk/Execution split) next — these reshape Prompt 08 and 09 before they're built.
3. Resolve F4 and F5 (evidence ordering, Learning feedback exception) — these are edits to `SYSTEM_ARCHITECTURE.md`'s dependency rules.
4. Resolve F3 (TQI R:R naming) — a small, contained edit to Prompt 07.
5. Everything else (F8–F22) can be addressed incrementally as each corresponding module is actually generated, since none of them block Module 02–06 (Regime, Bias, Liquidity, Zones, Session) from starting.

---

*This audit deliberately did not propose any new trading concepts, indicators, or changes to the evidence-based philosophy. Every finding is a software-engineering correction to what the existing architecture already commits to.*